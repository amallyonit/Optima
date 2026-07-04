// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, avoid_print, strict_top_level_inference

import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import '../../../api_helper.dart';
import '../../../classes/leads.dart';
import '../../../login_screen.dart';
import 'package:flutter/gestures.dart';
import '../../../notificationService.dart';
import '../ReportService.dart';
import '../dashboard_card_ui.dart';

final reportService = ReportService();

class SalesPerformancePage extends StatefulWidget {
  const SalesPerformancePage({super.key});

  @override
  SalesPerformancePageState createState() => SalesPerformancePageState();
}

class SalesTargetListSalesAnalysisProvider with ChangeNotifier {
  List<SalesTargetList> _salesTargetList = [];
  List<SalesTargetList> get salesTargetList => _salesTargetList;
  void updateSalesTargetList(List<SalesTargetList> newSalesTargetList) {
    _salesTargetList = newSalesTargetList;
    notifyListeners();
  }
}

List<SalesList> _allSales = []; // Master list for all loaded data
List<SalesList> sales = []; // Filtered list for UI

class SalesListSalesAnalysisProvider with ChangeNotifier {
  List<SalesList> _salesList = [];
  List<SalesList> get salesList => _salesList;
  void updateSalesList(List<SalesList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

final LongPressGestureRecognizer _longPressGestureRecognizer =
    LongPressGestureRecognizer();

int touchedMonthIndex = 0;
int? selectedMonthIndex = -1;
int selectedPiechartIndex = -1;
YTDSalesList ytdSalesList = YTDSalesList(ytdData: []);
ItemYTDSalesList ytdItemSalesList = ItemYTDSalesList(ytdData: []);
MonthlySalesList monthlySalesList = MonthlySalesList(monthlyData: []);
MonthlySalesList prevMonthlySalesList = MonthlySalesList(monthlyData: []);
ProductwiseSalesList productwiseSalesList = ProductwiseSalesList(
  productData: [],
);
CustomerWiseSalesList customerWiseSalesList = CustomerWiseSalesList(
  customerData: [],
);
PrevYearMonthList prevYearMonthList = PrevYearMonthList(prevYearMonthData: []);
TsmwiseSalesList tsmwiseSalesList = TsmwiseSalesList(tsmwiseData: []);
AsmwiseSalesList asmwiseSalesList = AsmwiseSalesList(asmwiseData: []);
RsmwiseSalesList rsmwiseSalesList = RsmwiseSalesList(rsmwiseData: []);
CustomerStateWiseSalesList customerStateWiseSalesList =
    CustomerStateWiseSalesList(customerStateData: []);
ProductGroupwiseSalesList productGroupwiseSalesList = ProductGroupwiseSalesList(
  productGroupData: [],
);
ProductGroupwiseSalesList itemGroupWiseData = ProductGroupwiseSalesList(
  productGroupData: [],
);
List<Users> usersListForFilter = [];
List<Users> usersList = [];
List<Users> childUsers = [];
String UserLevel = "0";
String UserName = "0";
String touchedRegionalManager = "";
String touchedSalesManager = "";
String touchedSalesRep = "";
String touchedMonth = "";
String touchedState = "";
String touchedCustomer = "";
String touchedProductGroup = "";
String touchedProduct = "";
double maxMonthY = 0.0;
double barChartWidthProduct = 0.0;
double maxItemMonthY = 0.0;
double selectedChart = 0;
List<MyNode> nodes = [];
List<Map<String, dynamic>> userList = [];
List<Map<String, dynamic>> salesTargetList = [];
late Future<void> loadDataFuture;
List<SalesTargetList> salesTarget = [];
String SalesGoalStr = "";
String CurrentMonthSalesStr = "";
double CurrentMonthSales = 0;
double SalesGoal = 0;
double LastMonthSales = 0;
String LastMonthSalesStr = "";
double LastMonthTarget = 0;
String LastMonthTargetStr = "";
int LastMonthPercentage = 0;
double CurrentQtrSales = 0;
String CurrentQtrSalesStr = "";
double CurrentQtrTarget = 0;
String CurrentQtrTargetStr = "";
int CurrentQtrPercentage = 0;
double YtdSales = 0;
String YtdSalesStr = "";
double YtdTarget = 0;
String YtdTargetStr = "";
int YtdPercentage = 0;
int CurrentMonthSalesPercentage = 0;
String CurrentMonthSalesPercentageStr = "";
String LastMonthPercentageStr = "";
String CurrentQtrPercentageStr = "";
String YtdPercentageStr = "";
List<Map<String, dynamic>> salesList = [];
bool noUserList = false;
bool chartDataLoaded = false;
bool YtdSalesBarChartData = false;
bool isLazyLoading = true;
DateTime? currentDate;
DateTime? currentMonthFromDate;
DateTime? lastMonthFromDate;
DateTime? lastMonthToDate;
DateTime? currentQuarterFromDate;
DateTime? currentQuarterToDate;
DateTime? lastQuarterFromDate;
DateTime? lastQuarterToDate;
DateTime? fiscalYearStartDate;
DateTime? prevFiscalYearStartDate;
DateTime? prevFiscalYearEndDate;
DateTime? q1FromDate;
DateTime? q1ToDate;
DateTime? q2FromDate;
DateTime? q2ToDate;
DateTime? q3FromDate;
DateTime? q3ToDate;
DateTime? q4FromDate;
DateTime? q4ToDate;
String financialYear = "";
String prevFinancialYear = "";
double selectedProduct = 0;
int currentQuarter = 0;
double Q1Sales = 0;
double Q1Target = 0;
double Q1Diff = 0;
int Q1Percentage = 0;
String Q1SalesStr = "";
String Q1TargetStr = "";
String Q1DiffStr = "";
String Q1PercentageStr = "";
double Q2Sales = 0;
double Q2Target = 0;
double Q2Diff = 0;
int Q2Percentage = 0;
String Q2SalesStr = "";
String Q2TargetStr = "";
String Q2DiffStr = "";
String Q2PercentageStr = "";
double Q3Sales = 0;
double Q3Target = 0;
double Q3Diff = 0;
int Q3Percentage = 0;
String Q3SalesStr = "";
String Q3TargetStr = "";
String Q3DiffStr = "";
String Q3PercentageStr = "";
double Q4Sales = 0;
double Q4Target = 0;
double Q4Diff = 0;
int Q4Percentage = 0;
String Q4SalesStr = "";
String Q4TargetStr = "";
String Q4DiffStr = "";
String Q4PercentageStr = "";

double Q1Average = 0;
String Q1AverageStr = "";
double Q2Average = 0;
String Q2AverageStr = "";
double Q3Average = 0;
String Q3AverageStr = "";
double Q4Average = 0;
String Q4AverageStr = "";

int loadedBatchCount = 0;
double animatedProgress = 0.0;

const int batchSize = 5000;
const int maxVisibleBlocks = 8;

final List<String> categories = ['RSM', 'ASM', 'TSM', 'Date'];

List<List<String>> filterOptions = [listOfRSM, listOfASM, listOfTSM, []];

List<String> listOfRSM = [];
List<String> listOfASM = [];
List<String> listOfTSM = [];

List<SalesList> filteredSales = [];
List<SalesTargetList> filteredTargets = [];

bool fromFilter = false;

int selectedCategoryIndex = 0;

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

Map<String, Map<String, bool>> allCategoriesState = {};

List<String> selectedSalesData = [];

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

Map<String, double> monthlySales = {};

class SalesPerformancePageState extends State<SalesPerformancePage> {
  bool showDrillDownChart = false;
  bool showProductSaleChart = false;
  bool showLastMonthBarChart = false;
  bool lastMonthChartFunc = false;
  bool lastThreeMonthChartFunc = false;
  bool touchedYearGraph = false;
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  bool showTooltipOnly = false;
  DateTime? touchStartTime;
  List<double> selectedMonthSales = [];
  int? tooltipIndex;
  bool showTooltip = false;
  ScrollController salesPerformancePageController = ScrollController();

  Future<void> _dateFilterTarget(
    String userName,
    String userLevel,
    bool fromFilter,
  ) async {
    context.read<SalesListSalesAnalysisProvider>().updateSalesList(sales);

    final filteredSales = sales.where((target) {
      final dueon = target.invoiceDate;

      if (fromDateFilter == null || toDateFilter == null) {
        return true;
      }

      return dueon.isAtLeast(fromDateFilter!) && dueon.isAtMost(toDateFilter!);
    }).toList();

    setState(() {
      sales = filteredSales;
    });
  }

  Future<void> filterFunction() async {
    setState(() {
      chartDataLoaded = false;
    });

    // Apply Date Filter
    await _dateFilterTarget("", "", false);

    // -----------------------------
    // Apply RSM / ASM / TSM Filters
    // -----------------------------

    final trueRSMOptions = (allCategoriesState['RSM'] ?? {}).entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final trueASMOptions = (allCategoriesState['ASM'] ?? {}).entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final trueTSMOptions = (allCategoriesState['TSM'] ?? {}).entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (trueRSMOptions.isNotEmpty) {
      sales = sales
          .where((e) => trueRSMOptions.contains(e.regionalManager))
          .toList();
    }

    if (trueASMOptions.isNotEmpty) {
      sales = sales
          .where((e) => trueASMOptions.contains(e.salesManager))
          .toList();
    }

    if (trueTSMOptions.isNotEmpty) {
      sales = sales.where((e) => trueTSMOptions.contains(e.salesRep)).toList();
    }

    buildFilteredLists();
    monthlySales = {};
    // -------------------------
    // Rebuild all calculations
    // -------------------------

    await _loadEachQtrValues();
    await _updateMonthlySales(filteredSales);
    await _loadMonthlySalesBarChartData(filteredSales, filteredTargets);

    showDrillDownChart = true;
    touchedYearGraph = true;
    showProductSaleChart = true;

    if (UserLevel != "1") {
      await _loadTSMSalesBarChartData(0, filteredSales, filteredTargets);

      await _loadASMSalesBarChartData(0, filteredSales, filteredTargets);

      await _loadRSMSalesBarChartData(0, filteredSales, filteredTargets);
    }

    await _loadMonthlyProductGroupwiseSalesBarChartData(0, filteredSales);

    await _loadMonthlyProductwiseSalesBarChartData(0, filteredSales);

    await _loadMonthlyCustomerStateWiseSalesBarChartData(0, filteredSales);

    await _loadMonthlyCustomerWiseSalesBarChartData(0, filteredSales);

    // -------------------------
    // Rebuild Filter Lists
    // -------------------------

    filterOptions = [listOfRSM, listOfASM, listOfTSM, []];

    if (savedFinanceReceivablesOptionsTemp.isEmpty) {
      savedFinanceReceivablesOptions = filterOptions
          .map((e) => List<bool>.filled(e.length, false))
          .toList();
    } else {
      savedFinanceReceivablesOptions = savedFinanceReceivablesOptionsTemp;
    }

    setState(() {
      chartDataLoaded = true;
    });
  }

  void resetFinanceReceivablesOptions() {
    setState(() {
      savedFinanceReceivablesOptions = List.from(
        selectedFinanceReceivablesOptions,
      );
    });
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  double roundUpToLakhs(double value, double roundValue) {
    return (value / roundValue).ceil() * roundValue.toDouble();
  }

  double roundDownToLakhs(double value, double roundValue) {
    return (value / roundValue).floor() * roundValue.toDouble();
  }

  double _chartAxisStep(double value) {
    final absValue = value.abs();
    if (absValue >= 10000000) {
      return 10000000;
    } else if (absValue >= 1000000) {
      return 1000000;
    } else if (absValue >= 50000) {
      return 50000;
    }
    return 1000;
  }

  double _roundedPositiveMaxY(Iterable<double> values) {
    final maxValue = values.fold<double>(
      0,
      (currentMax, value) => max(currentMax, value),
    );
    final step = _chartAxisStep(maxValue);
    return max(1, ((maxValue / step).floor() + 1) * step);
  }

  double _roundedNegativeMinY(Iterable<double> values) {
    final minValue = values.fold<double>(
      0,
      (currentMin, value) => min(currentMin, value),
    );
    if (minValue >= 0) {
      return 0;
    }
    final step = _chartAxisStep(minValue);
    return (minValue / step).floor() * step;
  }

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  SideTitles get _bottomTitles2 =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitles);

  SideTitles get _bottomTitlesTsm =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitlesTsm);

  SideTitles get _bottomTitlesAsm =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitlesAsm);

  SideTitles get _bottomTitlesRsm =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitlesRsm);

  Widget getBottomTitles(double val, TitleMeta meta) {
    String text = '';
    MonthlySalesData monthlySalesData = monthlySalesList.monthlyData.elementAt(
      val.toInt(),
    );
    text = monthlySalesData.monthName;
    return Text(text.length > 3 ? text.substring(0, 3) : text);
  }

  Widget getBottomTitlesRsm(double val, TitleMeta meta) {
    String text = '';
    RsmwiseData rsmwiseData = rsmwiseSalesList.rsmwiseData.elementAt(
      val.toInt(),
    );
    text = rsmwiseData.rsmName;
    return Text(text.length > 5 ? text.substring(0, 5) : text);
  }

  Widget getBottomTitlesAsm(double val, TitleMeta meta) {
    String text = '';
    AsmwiseData asmwiseData = asmwiseSalesList.asmwiseData.elementAt(
      val.toInt(),
    );
    text = asmwiseData.asmName;
    return Text(text.length > 5 ? text.substring(0, 5) : text);
  }

  Widget getBottomTitlesTsm(double val, TitleMeta meta) {
    String text = '';
    TsmwiseData tsmwiseData = tsmwiseSalesList.tsmwiseData.elementAt(
      val.toInt(),
    );
    text = tsmwiseData.tsmName;
    return Text(text.length > 5 ? text.substring(0, 5) : text);
  }

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
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

  SideTitles get _bottomTitlesProductGroup => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      ProductGroupwiseData productGroupData = productGroupwiseSalesList
          .productGroupData
          .elementAt(value.toInt());
      text = productGroupData.productGroupName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(
            '${text.length > 5 ? text.substring(0, 5) : text}...',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesProduct => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      ProductwiseData productwiseData = productwiseSalesList.productData
          .elementAt(value.toInt());
      text = productwiseData.productName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(
            '${text.length > 5 ? text.substring(0, 5) : text}...',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesCustomerState => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      int index = value.toInt();
      if (index >= 0 &&
          index < customerStateWiseSalesList.customerStateData.length) {
        CustomerStateWiseData customerStateData = customerStateWiseSalesList
            .customerStateData
            .elementAt(index);
        text = customerStateData.stateName;
      } else {
        text = '';
      }
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(
            '${text.length > 5 ? text.substring(0, 4) : text}...',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesCustomer => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      CustomerWiseData customerWiseData = customerWiseSalesList.customerData
          .elementAt(value.toInt());
      text = customerWiseData.customerName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(
            '${text.length > 5 ? text.substring(0, 5) : text}...',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    },
  );

  List<BarChartGroupData> _monthlySalesAnalysisChart(
    List<MonthlySalesData> monthlyData,
  ) {
    return monthlyData.asMap().entries.map((entry) {
      int index = entry.key;
      MonthlySalesData sales = entry.value;

      bool isSelected = selectedMonthIndex == index;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            backDrawRodData: BackgroundBarChartRodData(
              fromY: 0,
              toY: sales.salesTarget,
              show: true,
              color: isSelected
                  ? const Color(0xFFE87512)
                  : const Color(0xFFF49136),
            ),
            color: isSelected
                ? const Color(0xFF3BA8D7)
                : const Color(0xFF97D7F3),
            borderRadius: BorderRadius.zero,
            toY: sales.salesAmount,
            width: 30,
            borderSide: isSelected
                ? const BorderSide(color: Color(0xFF1F2937), width: 2)
                : BorderSide.none,
          ),
        ],
      );
    }).toList();
  }

  List<BarChartGroupData> _regionalManagerAnalysisChart(
    List<RsmwiseData> rsmwiseData,
  ) {
    return rsmwiseData
        .map(
          (rsm) => BarChartGroupData(
            x: rsmwiseData.indexOf(rsm),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: rsm.targetAmount,
                  show: true,
                  color: const Color(0xFFF49136),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: rsm.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _salesManagerAnalysisChart(
    List<AsmwiseData> asmwiseData,
  ) {
    return asmwiseData
        .map(
          (asm) => BarChartGroupData(
            x: asmwiseData.indexOf(asm),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: asm.targetAmount,
                  show: true,
                  color: const Color(0xFFF49136),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: asm.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _salesPersonAnalysisChart(
    List<TsmwiseData> tsmwiseData,
  ) {
    return tsmwiseData
        .map(
          (tsm) => BarChartGroupData(
            x: tsmwiseData.indexOf(tsm),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: tsm.targetAmount,
                  show: true,
                  color: const Color(0xFFF49136),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: tsm.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _productsGroupWiseAnalysisChart(
    List<ProductGroupwiseData> productGroupwiseSalesData,
  ) {
    return productGroupwiseSalesData
        .map(
          (sales) => BarChartGroupData(
            x: productGroupwiseSalesData.indexOf(sales),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: sales.targetAmount,
                  show: true,
                  color: const Color(0xFFF49136),
                ),
                borderRadius: BorderRadius.zero,
                color: const Color(0xFF97D7F3),
                toY: sales.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _productsWiseAnalysisChart(
    List<ProductwiseData> productwiseSalesData,
  ) {
    return productwiseSalesData
        .map(
          (sales) => BarChartGroupData(
            x: productwiseSalesData.indexOf(sales),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: sales.targetAmount,
                  show: true,
                  color: const Color(0xFFF49136),
                ),
                borderRadius: BorderRadius.zero,
                color: const Color(0xFF97D7F3),
                toY: sales.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _customerStateWiseAnalysisChart(
    List<CustomerStateWiseData> customerStateData,
  ) {
    return customerStateData
        .map(
          (sales) => BarChartGroupData(
            x: customerStateData.indexOf(sales),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: sales.targetAmount,
                  show: true,
                  color: const Color.fromARGB(255, 255, 159, 69),
                ),
                borderRadius: BorderRadius.zero,
                color: const Color(0xFF97D7F3),
                toY: sales.saleAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _customerWiseAnalysisChart(
    List<CustomerWiseData> customerData,
  ) {
    return customerData
        .map(
          (customer) => BarChartGroupData(
            x: customerData.indexOf(customer),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: customer.targetAmount,
                  show: true,
                  color: const Color(0xFFF49136),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: customer.saleAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  double getMaxValue(MonthlySalesList monthlySalesList) {
    return _roundedPositiveMaxY(
      monthlySalesList.monthlyData.expand(
        (monthlyData) => [monthlyData.salesAmount, monthlyData.salesTarget],
      ),
    );
  }

  double getCustomerStateMaxValue(
    CustomerStateWiseSalesList customerStateWiseSalesList,
  ) {
    return _roundedPositiveMaxY(
      customerStateWiseSalesList.customerStateData.expand(
        (soData) => [soData.saleAmount, soData.targetAmount],
      ),
    );
  }

  double getCustomerMaxValue(CustomerWiseSalesList customerAnalysisData) {
    return _roundedPositiveMaxY(
      customerAnalysisData.customerData.expand(
        (soData) => [soData.saleAmount, soData.targetAmount],
      ),
    );
  }

  double getRsmMaxValue(RsmwiseSalesList rsmManagerData) {
    return _roundedPositiveMaxY(
      rsmManagerData.rsmwiseData.expand(
        (soData) => [soData.salesAmount, soData.targetAmount],
      ),
    );
  }

  double getAsmMaxValue(AsmwiseSalesList salesManagerData) {
    return _roundedPositiveMaxY(
      salesManagerData.asmwiseData.expand(
        (soData) => [soData.salesAmount, soData.targetAmount],
      ),
    );
  }

  double getTsmMaxValue(TsmwiseSalesList salesPersonData) {
    return _roundedPositiveMaxY(
      salesPersonData.tsmwiseData.expand(
        (soData) => [soData.salesAmount, soData.targetAmount],
      ),
    );
  }

  double getItemGroupMaxValue(ProductGroupwiseSalesList itemGroupWiseData) {
    return _roundedPositiveMaxY(
      itemGroupWiseData.productGroupData.expand(
        (soData) => [soData.salesAmount, soData.targetAmount],
      ),
    );
  }

  double getItemMaxValue(ProductwiseSalesList itemAnalysisData) {
    return _roundedPositiveMaxY(
      itemAnalysisData.productData.expand(
        (soData) => [soData.salesAmount, soData.targetAmount],
      ),
    );
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  Future<void> _loadUserListForFilter(
    String userId,
    String userJwtToken,
    String userMailID,
    int userLevel,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}getusersforfilter';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            setState(() {
              usersListForFilter = (data)
                  .map((item) => Users.fromJson(item))
                  .toList();
            });
          }
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );
            navigateToLoginScreen();
          }
        }
      } else {
        if (!mounted) return;
        NotificationService.error(
          title: "Error",
          message: "User list not found.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading user list.",
      );
    }
  }

  Future<void> _loadUserList(
    String userId,
    String userJwtToken,
    String userMailID,
    int userLevel,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}getuserlist';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          List<Map<String, dynamic>> newUserList = [];
          if (data.isNotEmpty) {
            setState(() {
              usersList = (data).map((item) => Users.fromJson(item)).toList();
              childUsers = usersList
                  .where((element) => element.parentMenuId != 0)
                  .toList();
            });
          }
          for (var parent in usersList.where(
            (element) =>
                element.parentMenuId == 0 &&
                (element.userLevel == (userLevel > 3 ? 3 : 2)),
          )) {
            final rsm = {
              "MenuId": parent.menuId,
              "MenuName": parent.menuName,
              "SubMenuId": parent.subMenuId,
              "ParentMenuId": parent.parentMenuId,
              "UserLevel": parent.userLevel,
            };
            newUserList.add(rsm);
            for (var child in childUsers.where(
              (element) =>
                  element.parentMenuId == parent.menuId &&
                  (element.userLevel == (userLevel > 3 ? 2 : 1)),
            )) {
              final asm = {
                "MenuId": child.menuId,
                "MenuName": child.menuName,
                "SubMenuId": child.subMenuId,
                "ParentMenuId": child.parentMenuId,
                "UserLevel": child.userLevel,
              };
              newUserList.add(asm);
              for (var subChild in childUsers.where(
                (element) => element.parentMenuId == child.menuId,
              )) {
                final tsm = {
                  "MenuId": subChild.menuId,
                  "MenuName": subChild.menuName,
                  "SubMenuId": subChild.subMenuId,
                  "ParentMenuId": subChild.parentMenuId,
                  "UserLevel": subChild.userLevel,
                };
                newUserList.add(tsm);
              }
            }
          }
          setState(() {
            userList = newUserList;
            nodes = convertJsonToNodes(userList);
            noUserList = true;
          });
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );
            navigateToLoginScreen();
          } else {
            setState(() {
              nodes = convertJsonToNodes(userList);
              nodes.add(MyNode(title: "", id: 0));
              noUserList = false;
            });
          }
        }
      } else {
        if (!mounted) return;
        NotificationService.error(
          title: "Error",
          message: "User list not found.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading user list.",
      );
    }
  }

  List<MyNode> convertJsonToNodes(List<Map<String, dynamic>> jsonData) {
    List<MyNode> nodes = [];
    Map<int, MyNode> map = {};

    for (var item in jsonData) {
      int menuId = item['MenuId'];
      String title = item['MenuName'];

      MyNode node = MyNode(title: title, id: menuId);
      map[menuId] = node;

      if (item['ParentMenuId'] != 0) {
        int parentId = item['ParentMenuId'];
        MyNode parent = map[parentId]!;
        parent.children = [...parent.children, node];
      } else {
        nodes.add(node);
      }
    }
    return nodes;
  }

  Future<void> _loadSalesTarget(String UserName, String UserLevel) async {
    final body = {
      "Index": 0,
      "Limit": 0,
      "sapToken": DataManager.readSapToken(),
    };
    const apiUrl = '${ApiHelper.baseUrl}BicxoSalesTargetList';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson["responseData"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['responseData'];
          if (data.isNotEmpty) {
            List<SalesTargetList> newSalesTargetList = (data)
                .map((item) => SalesTargetList.fromJson(item))
                .toList();
            int monthIndex = currentDate!.month;
            setState(() {
              List<String> menuNames = usersList
                  .where((element) => element.parentMenuId == 0)
                  .map((user) => user.menuName)
                  .toList();
              menuNames.insert(0, UserName);
              context
                  .read<SalesTargetListSalesAnalysisProvider>()
                  .updateSalesTargetList(newSalesTargetList);
              if (int.parse(UserLevel) == 5) {
                salesTarget = newSalesTargetList.where((element) {
                  if (monthIndex == 4) {
                    return (element.financialYear == financialYear ||
                        element.financialYear == prevFinancialYear);
                  } else {
                    return element.financialYear == financialYear;
                  }
                }).toList();
              } else if (int.parse(UserLevel) == 4) {
                salesTarget = newSalesTargetList.where((element) {
                  if (monthIndex == 4) {
                    return element.regionalManager == UserName &&
                        (element.financialYear == financialYear ||
                            element.financialYear == prevFinancialYear);
                  } else {
                    return element.regionalManager == UserName &&
                        element.financialYear == financialYear;
                  }
                }).toList();
              } else if (int.parse(UserLevel) <= 3 &&
                  int.parse(UserLevel) >= 2) {
                salesTarget = newSalesTargetList.where((element) {
                  if (monthIndex == 4) {
                    return menuNames.contains(element.salesManager) &&
                        (element.financialYear == financialYear ||
                            element.financialYear == prevFinancialYear);
                  } else {
                    return menuNames.contains(element.salesManager) &&
                        element.financialYear == financialYear;
                  }
                }).toList();
              } else {
                salesTarget = newSalesTargetList.where((element) {
                  if (monthIndex == 4) {
                    return element.salesRep == UserName &&
                        (element.financialYear == financialYear ||
                            element.financialYear == prevFinancialYear);
                  } else {
                    return element.salesRep == UserName &&
                        element.financialYear == financialYear;
                  }
                }).toList();
              }
            });
            String Month = getMonthName(monthIndex);
            double sum = 0.00;
            for (var target in salesTarget.where(
              (element) => element.financialYear == financialYear,
            )) {
              sum += double.tryParse(target.getTargetForMonth(Month)) ?? 0;
            }
            SalesGoal = sum;
            SalesGoalStr = "${(sum / 100000).toStringAsFixed(2)} L";

            sum = 0;
            LastMonthTarget = 0;
            Month = getMonthName(monthIndex - 1);
            if (monthIndex != 4) {
              for (var target in salesTarget.where(
                (element) => element.financialYear == financialYear,
              )) {
                sum += double.tryParse(target.getTargetForMonth(Month)) ?? 0;
              }
            } else {
              for (var target in salesTarget.where(
                (element) => element.financialYear == prevFinancialYear,
              )) {
                sum += double.tryParse(target.getTargetForMonth(Month)) ?? 0;
              }
            }
            LastMonthTarget = sum;
            LastMonthTargetStr =
                "${(LastMonthTarget / 100000).toStringAsFixed(2)} L";

            sum = 0;
            for (var target in salesTarget.where(
              (element) => element.financialYear == financialYear,
            )) {
              sum +=
                  double.tryParse(
                    target.getTargetForMonth(
                      getMonthName(currentQuarterFromDate!.month),
                    ),
                  ) ??
                  0;
              sum +=
                  double.tryParse(
                    target.getTargetForMonth(
                      getMonthName(currentQuarterFromDate!.month + 1),
                    ),
                  ) ??
                  0;
              sum +=
                  double.tryParse(
                    target.getTargetForMonth(
                      getMonthName(currentQuarterFromDate!.month + 2),
                    ),
                  ) ??
                  0;
            }
            CurrentQtrTarget = sum;
            CurrentQtrTargetStr =
                "${(CurrentQtrTarget / 100000).toStringAsFixed(2)} L";

            sum = 0;
            for (var target in salesTarget.where(
              (element) => element.financialYear == financialYear,
            )) {
              for (int i = 1; i <= 12; i++) {
                sum +=
                    double.tryParse(
                      target.getTargetForMonth(getMonthName(i)),
                    ) ??
                    0;
              }
            }
            YtdTarget = sum;
            YtdTargetStr = "${(YtdTarget / 100000).toStringAsFixed(2)} L";
          }
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );
            navigateToLoginScreen();
          } else {
            if (!mounted) return;
            NotificationService.error(
              title: "Error",
              message: responseJson["Error"].toString(),
            );
          }
        }
      } else {
        if (!mounted) return;
        NotificationService.error(
          title: "Error",
          message: "Sales target details not found.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading sales target.",
      );
    }
  }

  Future<void> _loadSalesWithLazyLoading(
    String userName,
    String userLevel,
  ) async {
    final Stopwatch watch = Stopwatch()..start();
    sales.clear();

    // Load first page quickly
    await _loadInitialSales(userName, userLevel);
    buildFilteredLists();
    loadedBatchCount++;
    _updateSteppedProgress();
    watch.stop();
    // print('Initial visible load time: ${watch.elapsedMilliseconds} ms');

    // Start background loading (non-blocking)
    _loadSalesInBackground(userName: userName, userLevel: userLevel);
  }

  Future<void> _updateMonthlySales(List<SalesList> batch) async {
    for (final s in batch) {
      final DateTime d = s.invoiceDate;

      final int m = d.month;

      final String monthName = (m >= 4)
          ? getMonthName(m)
          : getMonthName(m + 12);

      final double val = double.tryParse(s.rowTotal) ?? 0;

      monthlySales[monthName] = (monthlySales[monthName] ?? 0) + val;
    }
  }

  Future<void> _loadInitialSales(String userName, String userLevel) async {
    const int limit = 5000;
    const int index = 0;
    monthlySales.clear();
    final body = {
      "FromDate": formatDate(
        currentDate!.month == 4 ? lastMonthFromDate! : fiscalYearStartDate!,
      ),
      "ToDate": formatDate(currentDate!),
      "Index": index.toString(),
      "Limit": limit.toString(),
      "sapToken": DataManager.readSapToken(),
    };
    final response = await http.post(
      Uri.parse('${ApiHelper.baseUrl}Crm_SalesList'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptEncodingHeader: 'gzip',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) return;
    final json = jsonDecode(response.body);
    final List list = json['responseData'] ?? [];
    final initialSales = list.map((e) => SalesList.fromJson(e)).toList();

    setState(() {
      _allSales.clear();
      _allSales.addAll(initialSales); // Save all loaded data
      // Apply filters to master list
      sales = _applyUserFilter(initialSales, userName, userLevel);
      _updateMonthlySales(initialSales);
    });
    _calculateSalesTotals();
  }

  void _updateSteppedProgress() {
    // Each batch adds 10%, capped at 90%
    final double nextProgress = (loadedBatchCount * 0.10).clamp(0.0, 0.9);

    setState(() {
      animatedProgress = nextProgress;
    });
  }

  void _completeProgress() {
    setState(() {
      animatedProgress = 1.0;
    });

    // Optional: hide after animation
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        animatedProgress = 0.0;
      });
    });
  }

  Future<void> _loadSalesInBackground({
    required String userName,
    required String userLevel,
  }) async {
    const int limit = 5000;
    int index = 1;
    bool hasMore = true;
    final Stopwatch watch = Stopwatch()..start();
    while (hasMore) {
      try {
        final body = {
          "FromDate": formatDate(
            currentDate!.month == 4 ? lastMonthFromDate! : fiscalYearStartDate!,
          ),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        final response = await http.post(
          Uri.parse('${ApiHelper.baseUrl}Crm_SalesList'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.acceptEncodingHeader: 'gzip',
          },
          body: jsonEncode(body),
        );
        if (response.statusCode != 200) break;
        final json = jsonDecode(response.body);
        final List list = json['responseData'] ?? [];
        // final newSales = await parseSales(response.body);
        if (list.isEmpty) {
          hasMore = false;
          _completeProgress();
          watch.stop();
          buildFilteredLists();
          print('Final load time: ${watch.elapsedMilliseconds} ms');
          break;
        }
        final newSales = list.map((e) => SalesList.fromJson(e)).toList();
        setState(() {
          _allSales.addAll(newSales); // Append to master list

          // Re-filter full master list
          sales.addAll(_applyUserFilter(newSales, userName, userLevel));
          _updateMonthlySales(newSales);
        });

        _calculateSalesTotals();
        index++;
        loadedBatchCount++;
        _updateSteppedProgress();
        // Small delay avoids network congestion
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('Background load error: $e');
        break;
      }
    }

    await _loadEachQtrValues();
    await _loadMonthlySalesBarChartData(filteredSales, filteredTargets);
    showDrillDownChart = true;
    touchedYearGraph = true;
    showProductSaleChart = true;
    if (UserLevel != "1") {
      await _loadTSMSalesBarChartData(0, filteredSales, filteredTargets);
      await _loadASMSalesBarChartData(0, filteredSales, filteredTargets);
      await _loadRSMSalesBarChartData(0, filteredSales, filteredTargets);
    }
    await _loadMonthlyProductGroupwiseSalesBarChartData(0, filteredSales);
    await _loadMonthlyProductwiseSalesBarChartData(0, filteredSales);
    await _loadMonthlyCustomerStateWiseSalesBarChartData(0, filteredSales);
    await _loadMonthlyCustomerWiseSalesBarChartData(0, filteredSales);
    setState(() {
      filterOptions = [listOfRSM, listOfASM, listOfTSM, []];
      savedFinanceReceivablesOptions = filterOptions
          .map((options) => List<bool>.filled(options.length, false))
          .toList();
      if (savedFinanceReceivablesOptionsTemp.isEmpty) {
        savedFinanceReceivablesOptions = filterOptions
            .map((options) => List<bool>.filled(options.length, false))
            .toList();
      } else {
        savedFinanceReceivablesOptions = savedFinanceReceivablesOptionsTemp;
      }
      chartDataLoaded = true;
      isLazyLoading = false;
    });
  }

  List<SalesList> _applyUserFilter(
    List<SalesList> list,
    String userName,
    String userLevel,
  ) {
    final int level = int.parse(userLevel);

    if (level == 5) return list;

    final menuNames =
        usersList
            .where((e) => e.parentMenuId == 0)
            .map((e) => e.menuName)
            .toList()
          ..insert(0, userName);

    return list.where((e) {
      if (level == 4 && e.regionalManager != userName) {
        return false;
      }

      if (level >= 2 && level <= 3 && !menuNames.contains(e.salesManager)) {
        return false;
      }

      if (level < 2 && e.salesRep != userName) {
        return false;
      }

      return true;
    }).toList();
  }

  void _calculateSalesTotals() {
    double sumCurrentMonth = 0;
    double sumLastMonth = 0;
    double sumCurrentQtr = 0;
    double sumYtd = 0;
    for (var target in sales) {
      final DateTime invoiceDate = target.invoiceDate;
      final double salesAmt = double.tryParse(target.rowTotal) ?? 0;
      if (invoiceDate.isAtLeast(currentMonthFromDate!) &&
          invoiceDate.isAtMost(currentDate!)) {
        sumCurrentMonth += salesAmt;
      }
      if (invoiceDate.isAtLeast(lastMonthFromDate!) &&
          invoiceDate.isAtMost(lastMonthToDate!)) {
        sumLastMonth += salesAmt;
      }
      if (invoiceDate.isAtLeast(currentQuarterFromDate!) &&
          invoiceDate.isAtMost(currentQuarterToDate!)) {
        sumCurrentQtr += salesAmt;
      }
      if (invoiceDate.isAtLeast(fiscalYearStartDate!) &&
          invoiceDate.isAtMost(currentDate!)) {
        sumYtd += salesAmt;
      }
    }
    setState(() {
      CurrentMonthSales = sumCurrentMonth;
      CurrentMonthSalesStr =
          "${(sumCurrentMonth / 100000).toStringAsFixed(2)} L";
      if (CurrentMonthSales == 0) {
        CurrentMonthSalesPercentage = 0;
      } else {
        CurrentMonthSalesPercentage =
            double.tryParse(
              ((CurrentMonthSales / SalesGoal) * 100).toStringAsFixed(0),
            )?.ceil() ??
            0;
      }
      CurrentMonthSalesPercentageStr =
          "${CurrentMonthSalesPercentage.toString()} %";
      if (CurrentMonthSalesPercentage > 100) {
        CurrentMonthSalesPercentage = 100;
      }
      LastMonthSales = sumLastMonth;
      LastMonthSalesStr = "${(sumLastMonth / 100000).toStringAsFixed(2)} L";
      if (LastMonthSales == 0) {
        LastMonthPercentage = 0;
      } else {
        LastMonthPercentage =
            double.tryParse(
              ((LastMonthSales / LastMonthTarget) * 100).toStringAsFixed(2),
            )?.ceil() ??
            0;
      }
      LastMonthPercentageStr = "${LastMonthPercentage.toString()} %";
      if (LastMonthPercentage > 100) {
        LastMonthPercentage = 100;
      }
      CurrentQtrSales = sumCurrentQtr;
      CurrentQtrSalesStr = "${(sumCurrentQtr / 100000).toStringAsFixed(2)} L";
      if (CurrentQtrSales == 0) {
        CurrentQtrPercentage = 0;
      } else {
        CurrentQtrPercentage =
            double.tryParse(
              ((CurrentQtrSales / CurrentQtrTarget) * 100).toStringAsFixed(2),
            )?.ceil() ??
            0;
      }
      CurrentQtrPercentageStr = "${CurrentQtrPercentage.toString()} %";
      if (CurrentQtrPercentage > 100) {
        CurrentQtrPercentage = 100;
      }
      YtdSales = sumYtd;
      YtdSalesStr = "${(sumYtd / 100000).toStringAsFixed(2)} L";
      if (YtdSales == 0) {
        YtdPercentage = 0;
      } else {
        YtdPercentage =
            double.tryParse(
              ((YtdSales / YtdTarget) * 100).toStringAsFixed(2),
            )?.ceil() ??
            0;
      }
      YtdPercentageStr = "${YtdPercentage.toString()} %";
      if (YtdPercentage > 100) {
        YtdPercentage = 100;
      }
    });
  }

  void buildFilteredLists({
    String regionalManager = "",
    String salesManager = "",
    String salesRep = "",
    String stateName = "",
    String customerCode = "",
    String productGroupCode = "",
    String productCode = "",
  }) {
    filteredSales = filterSalesList(
      sales,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      customerCode: customerCode,
      productGroupCode: productGroupCode,
      productCode: productCode,
    );

    filteredTargets = filterSalesTargetList(
      salesTarget,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
    );
  }

  String getFullMonthName(String shortMonth) {
    switch (shortMonth) {
      case 'jan':
        return 'january';
      case 'feb':
        return 'february';
      case 'mar':
        return 'march';
      case 'april':
        return 'april';
      case 'may':
        return 'may';
      case 'june':
        return 'june';
      case 'july':
        return 'july';
      case 'aug':
        return 'august';
      case 'sep':
        return 'september';
      case 'oct':
        return 'october';
      case 'nov':
        return 'november';
      case 'dec':
        return 'december';

      default:
        throw Exception("Invalid month short name: $shortMonth");
    }
  }

  int monthDifference(DateTime startDate, DateTime endDate) {
    int years = endDate.year - startDate.year;
    int months = endDate.month - startDate.month;
    int differenceInMonths = (years * 12) + months;
    return differenceInMonths;
  }

  Future<void> _loadEachQtrValues() async {
    double sum = 0;
    int MonthDiffs = 0;
    for (int i = 1; i <= getCurrentQuarter(); i++) {
      switch (i) {
        case 1:
          sum = 0;
          MonthDiffs = monthDifference(q1FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q1FromDate!, currentDate!);
          for (var target in salesTarget.where(
            (element) => element.financialYear == financialYear,
          )) {
            for (int i = 4; i <= 6; i++) {
              sum +=
                  double.tryParse(target.getTargetForMonth(getMonthName(i))) ??
                  0;
            }
          }
          Q1Target = sum;
          Q1TargetStr = "${(Q1Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = sales.where((target) {
            DateTime invoiceDate = target.invoiceDate;
            return invoiceDate.isAtLeast(q1FromDate!) &&
                invoiceDate.isAtMost(q1ToDate!);
          });
          sum = 0;
          double salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            salesAmt = double.tryParse(target.rowTotal) ?? 0;
            sum += salesAmt;
          }

          Q1Sales = sum;
          Q1SalesStr = "${(Q1Sales / 100000).toStringAsFixed(2)} L";
          if (Q1Sales == 0) {
            Q1Percentage = 0;
          } else {
            Q1Target == 0
                ? Q1Percentage = 0
                : Q1Percentage =
                      double.tryParse(
                        ((Q1Sales / Q1Target) * 100).toStringAsFixed(2),
                      )?.ceil() ??
                      0;
          }
          Q1PercentageStr = "${Q1Percentage.toString()}%";
          Q1Average = (Q1Sales / MonthDiffs);
          Q1AverageStr = "${(Q1Average / 100000).toStringAsFixed(2)} L";
          Q1DiffStr =
              "${((Q1Target - Q1Sales > 0 ? Q1Target - Q1Sales : 0) / 100000).toStringAsFixed(2)} L";
          break;
        case 2:
          sum = 0;
          MonthDiffs = monthDifference(q2FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q2FromDate!, currentDate!);
          for (var target in salesTarget.where(
            (element) => element.financialYear == financialYear,
          )) {
            for (int i = 7; i <= 9; i++) {
              sum +=
                  double.tryParse(target.getTargetForMonth(getMonthName(i))) ??
                  0;
            }
          }

          Q2Target = sum;
          Q2TargetStr = "${(Q2Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = sales.where((target) {
            DateTime invoiceDate = target.invoiceDate;

            return invoiceDate.isAtLeast(q2FromDate!) &&
                invoiceDate.isAtMost(q2ToDate!);
          });
          sum = 0;
          double salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            salesAmt = double.tryParse(target.rowTotal) ?? 0;
            sum += salesAmt;
          }

          Q2Sales = sum;
          Q2SalesStr = "${(Q2Sales / 100000).toStringAsFixed(2)} L";
          if (Q2Sales == 0) {
            Q2Percentage = 0;
          } else {
            Q2Target == 0
                ? Q2Percentage = 0
                : Q2Percentage =
                      double.tryParse(
                        ((Q2Sales / Q2Target) * 100).toStringAsFixed(2),
                      )?.ceil() ??
                      0;
          }
          Q2PercentageStr = "${Q2Percentage.toString()}%";
          Q2Average = (Q2Sales / MonthDiffs);
          Q2AverageStr = "${(Q2Average / 100000).toStringAsFixed(2)} L";
          Q2DiffStr =
              "${((Q2Target - Q2Sales > 0 ? Q2Target - Q2Sales : 0) / 100000).toStringAsFixed(2)} L";
          break;
        case 3:
          sum = 0;
          MonthDiffs = monthDifference(q3FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q3FromDate!, currentDate!);
          for (var target in salesTarget.where(
            (element) => element.financialYear == financialYear,
          )) {
            for (int i = 10; i <= 12; i++) {
              sum +=
                  double.tryParse(target.getTargetForMonth(getMonthName(i))) ??
                  0;
            }
          }
          Q3Target = sum;
          Q3TargetStr = "${(Q3Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = sales.where((target) {
            DateTime invoiceDate = target.invoiceDate;

            return invoiceDate.isAtLeast(q3FromDate!) &&
                invoiceDate.isAtMost(q3ToDate!);
          });
          sum = 0;
          double salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            salesAmt = double.tryParse(target.rowTotal) ?? 0;
            sum += salesAmt;
          }

          Q3Sales = sum;
          Q3SalesStr = "${(Q3Sales / 100000).toStringAsFixed(2)} L";
          if (Q3Sales == 0) {
            Q3Percentage = 0;
          } else {
            Q3Target == 0
                ? Q3Percentage =
                      double.tryParse(
                        ((Q3Sales / 1) * 100).toStringAsFixed(2),
                      )?.ceil() ??
                      0
                : Q3Percentage =
                      double.tryParse(
                        ((Q3Sales / Q3Target) * 100).toStringAsFixed(2),
                      )?.ceil() ??
                      0;
          }
          Q3PercentageStr = "${Q3Percentage.toString()}%";
          Q3Average = (Q3Sales / MonthDiffs);
          Q3AverageStr = "${(Q3Average / 100000).toStringAsFixed(2)} L";
          Q3DiffStr =
              "${((Q3Target - Q3Sales > 0 ? Q3Target - Q3Sales : 0) / 100000).toStringAsFixed(2)} L";
          break;
        case 4:
          sum = 0;
          MonthDiffs = monthDifference(q4FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q4FromDate!, currentDate!);
          for (var target in salesTarget.where(
            (element) => element.financialYear == financialYear,
          )) {
            for (int i = 1; i <= 3; i++) {
              sum +=
                  double.tryParse(target.getTargetForMonth(getMonthName(i))) ??
                  0;
            }
          }
          Q4Target = sum;
          Q4TargetStr = "${(Q4Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = sales.where((target) {
            DateTime invoiceDate = target.invoiceDate;

            return invoiceDate.isAtLeast(q4FromDate!) &&
                invoiceDate.isAtMost(q4ToDate!);
          });
          sum = 0;
          double salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            salesAmt = double.tryParse(target.rowTotal) ?? 0;
            sum += salesAmt;
          }
          Q4Sales = sum;
          Q4SalesStr = "${(Q4Sales / 100000).toStringAsFixed(2)} L";
          if (Q4Sales == 0) {
            Q4Percentage = 0;
          } else {
            Q4Target == 0
                ? Q4Percentage = 0
                : Q4Percentage =
                      double.tryParse(
                        ((Q4Sales / Q4Target) * 100).toStringAsFixed(2),
                      )?.ceil() ??
                      0;
          }
          Q4PercentageStr = "${Q4Percentage.toString()}%";
          Q4Average = (Q4Sales / MonthDiffs);
          Q4AverageStr = "${(Q4Average / 100000).toStringAsFixed(2)} L";
          Q4DiffStr =
              "${((Q4Target - Q4Sales > 0 ? Q4Target - Q4Sales : 0) / 100000).toStringAsFixed(2)} L";
          break;
        default:
      }
    }
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

  DateTime addOneMonth(DateTime date) {
    int currentMonth = date.month;
    int currentYear = date.year;
    int nextMonth = currentMonth + 1;
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

  bool matchHierarchy({
    required String rowRsm,
    required String rowAsm,
    required String rowTsm,
    required List<Users> userNames,
    String? regionalManager,
    String? salesManager,
    String? salesRep,
  }) {
    int regionalMenuId = -1;
    int salesMenuId = -1;

    Set<String> regionalChildren = {};
    Set<String> salesChildren = {};

    if (regionalManager != null && regionalManager.isNotEmpty) {
      regionalMenuId = userNames
          .firstWhere(
            (e) => e.menuName == regionalManager,
            orElse: () => Users(
              menuId: -1,
              menuName: '',
              subMenuId: -1,
              parentMenuId: -1,
              userLevel: -1,
            ),
          )
          .menuId;

      if (regionalMenuId != -1) {
        regionalChildren = userNames
            .where((e) => e.parentMenuId == regionalMenuId)
            .map((e) => e.menuName)
            .toSet();
      }

      if (regionalManager != rowRsm) return false;

      if (regionalChildren.isNotEmpty && !regionalChildren.contains(rowAsm)) {
        return false;
      }
    }

    if (salesManager != null && salesManager.isNotEmpty) {
      salesMenuId = userNames
          .firstWhere(
            (e) => e.menuName == salesManager,
            orElse: () => Users(
              menuId: -1,
              menuName: '',
              subMenuId: -1,
              parentMenuId: -1,
              userLevel: -1,
            ),
          )
          .menuId;

      if (salesMenuId != -1) {
        salesChildren = userNames
            .where((e) => e.parentMenuId == salesMenuId)
            .map((e) => e.menuName)
            .toSet();
      }

      if (salesManager != rowAsm) return false;

      if (salesChildren.isNotEmpty && !salesChildren.contains(rowTsm)) {
        return false;
      }
    }

    if (salesRep != null && salesRep.isNotEmpty && rowTsm != salesRep) {
      return false;
    }

    return true;
  }

  List<SalesList> filterSalesList(
    List<SalesList> salesList,
    List<Users> userNames, {
    String? regionalManager,
    String? salesManager,
    String? salesRep,
    String? stateName,
    String? customerCode,
    String? productGroupCode,
    String? productCode,
  }) {
    List<SalesList> result = [];

    for (var sale in salesList) {
      if (!matchHierarchy(
        rowRsm: sale.regionalManager,
        rowAsm: sale.salesManager,
        rowTsm: sale.salesRep,
        userNames: userNames,
        regionalManager: regionalManager,
        salesManager: salesManager,
        salesRep: salesRep,
      )) {
        continue;
      }

      if (stateName != null &&
          stateName.isNotEmpty &&
          sale.customerState != stateName) {
        continue;
      }

      if (customerCode != null &&
          customerCode.isNotEmpty &&
          sale.customerCode != customerCode) {
        continue;
      }

      if (productCode != null &&
          productCode.isNotEmpty &&
          sale.code != productCode) {
        continue;
      }

      if (productGroupCode != null &&
          productGroupCode.isNotEmpty &&
          sale.itemSubGroup != productGroupCode) {
        continue;
      }

      result.add(sale);
    }

    return result;
  }

  List<SalesTargetList> filterSalesTargetList(
    List<SalesTargetList> salesTargetList,
    List<Users> userNames, {
    String? regionalManager,
    String? salesManager,
    String? salesRep,
  }) {
    List<SalesTargetList> result = [];

    for (var target in salesTargetList) {
      if (!matchHierarchy(
        rowRsm: target.regionalManager,
        rowAsm: target.salesManager,
        rowTsm: target.salesRep,
        userNames: userNames,
        regionalManager: regionalManager,
        salesManager: salesManager,
        salesRep: salesRep,
      )) {
        continue;
      }

      result.add(target);
    }

    return result;
  }

  Future<void> _loadMonthlySalesBarChartData(
    List<SalesList> filteredSales,
    List<SalesTargetList> filteredTargets,
  ) async {
    List<MonthlySalesData> monthlyDataList = [];

    prevYearMonthList = PrevYearMonthList(prevYearMonthData: []);

    Map<String, double> targetMap = {};

    for (var t in filteredTargets) {
      if (t.financialYear != financialYear) continue;

      for (int i = 4; i <= 15; i++) {
        String monthName = getMonthName(i);

        targetMap[monthName] =
            (targetMap[monthName] ?? 0) +
            (double.tryParse(t.getTargetForMonth(monthName)) ?? 0);
      }
    }

    for (int i = 4; i <= 15; i++) {
      String monthName = getMonthName(i);

      monthlyDataList.add(
        MonthlySalesData(
          monthName: monthName,
          salesAmount: monthlySales[monthName] ?? 0,
          salesTarget: targetMap[monthName] ?? 0,
        ),
      );
    }

    monthlySalesList = MonthlySalesList(monthlyData: monthlyDataList);
  }

  Future<void> _loadYtdSalesBarChartData() async {
    Map<String, List<SalesList>> salesByCustomer = {};
    Map<String, List<SalesList>> salesByItem = {};

    List<YTDSalesData> ytdSalesDataList = [];
    var tmpSales = sales.toList();

    for (var sale in tmpSales) {
      salesByCustomer.putIfAbsent(sale.customerCode, () => []).add(sale);
    }

    for (var customerCode in salesByCustomer.keys) {
      var customerSales = salesByCustomer[customerCode]!;
      var firstSale = customerSales.first;

      salesByItem.clear();
      for (var sale in customerSales) {
        salesByItem.putIfAbsent(sale.code, () => []).add(sale);
      }

      for (var itemCode in salesByItem.keys) {
        var itemSales = salesByItem[itemCode]!;
        var firstItemSale = itemSales.first;

        List<double> monthlyQty = List.filled(12, 0.0);
        List<double> monthlyValue = List.filled(12, 0.0);

        for (int i = 0; i < 12; i++) {
          DateTime startDate = addMonth(fiscalYearStartDate!, i);
          DateTime endDate = addMonth(
            startDate,
            1,
          ).add(const Duration(days: -1));

          for (var sale in itemSales) {
            DateTime invoiceDate = sale.invoiceDate;
            if (invoiceDate.isAtLeast(startDate) &&
                invoiceDate.isAtMost(endDate)) {
              double rowTotal = double.tryParse(sale.rowTotal) ?? 0.0;
              double quantity = double.tryParse(sale.quantity) ?? 0.0;
              // if (sale.invoiceType == "Sales Return") {
              //   rowTotal *= -1;
              //   quantity *= -1;
              // }
              monthlyValue[i] += rowTotal;
              monthlyQty[i] += quantity;
            }
          }
        }
        if (monthlyValue.reduce((a, b) => a + b) != 0) {
          ytdSalesDataList.add(
            YTDSalesData(
              customerName: firstSale.customerName,
              salesManager: firstSale.salesManager,
              salesRep: firstSale.salesRep,
              itemSubGroup: firstItemSale.itemSubGroup,
              itemName: firstItemSale.description,
              currency: firstSale.currency,
              currencyRate: double.tryParse(firstItemSale.currencyRate) ?? 0.0,
              price: double.tryParse(firstItemSale.price) ?? 0.0,
              aprQty: monthlyQty[0],
              aprValue: monthlyValue[0],
              mayQty: monthlyQty[1],
              mayValue: monthlyValue[1],
              junQty: monthlyQty[2],
              junValue: monthlyValue[2],
              julQty: monthlyQty[3],
              julValue: monthlyValue[3],
              augQty: monthlyQty[4],
              augValue: monthlyValue[4],
              sepQty: monthlyQty[5],
              sepValue: monthlyValue[5],
              octQty: monthlyQty[6],
              octValue: monthlyValue[6],
              novQty: monthlyQty[7],
              novValue: monthlyValue[7],
              decQty: monthlyQty[8],
              decValue: monthlyValue[8],
              janQty: monthlyQty[9],
              janValue: monthlyValue[9],
              febQty: monthlyQty[10],
              febValue: monthlyValue[10],
              marQty: monthlyQty[11],
              marValue: monthlyValue[11],
              ytdTotalValue: monthlyValue.reduce((a, b) => a + b),
              ytdTotalQty: monthlyQty.reduce((a, b) => a + b),
            ),
          );
        }
        customerSales.clear();
      }
    }

    setState(() {
      ytdSalesDataList.sort((a, b) => a.customerName.compareTo(b.customerName));
      ytdSalesList = YTDSalesList(ytdData: ytdSalesDataList);
      YtdSalesBarChartData = true;
    });
  }

  Future<void> _loadMonthlyItemSalesData() async {
    Map<String, List<SalesList>> salesByCustomer = {};
    Map<String, List<SalesList>> salesByItem = {};

    List<ItemYTDSalesData> ytdSalesDataList = [];
    var tmpSales = sales.toList();

    for (var sale in tmpSales) {
      salesByCustomer.putIfAbsent(sale.itemSubGroup, () => []).add(sale);
    }

    for (var itemGroup in salesByCustomer.keys) {
      var customerSales = salesByCustomer[itemGroup]!;

      salesByItem.clear();
      for (var sale in customerSales) {
        salesByItem.putIfAbsent(sale.itemSubGroup, () => []).add(sale);
      }

      for (var itemGroup in salesByItem.keys) {
        var itemSales = salesByItem[itemGroup]!;
        var firstItemSale = itemSales.first;

        List<double> monthlyQty = List.filled(12, 0.0);
        List<double> monthlyValue = List.filled(12, 0.0);

        for (int i = 0; i < 12; i++) {
          DateTime startDate = addMonth(fiscalYearStartDate!, i);
          DateTime endDate = addMonth(
            startDate,
            1,
          ).add(const Duration(days: -1));

          for (var sale in itemSales) {
            DateTime invoiceDate = sale.invoiceDate;

            if (invoiceDate.isAtLeast(startDate) &&
                invoiceDate.isAtMost(endDate)) {
              double rowTotal = double.tryParse(sale.rowTotal) ?? 0.0;
              double quantity = double.tryParse(sale.quantity) ?? 0.0;
              // if (sale.invoiceType == "Sales Return") {
              //   rowTotal *= -1;
              //   quantity *= -1;
              // }
              monthlyValue[i] += rowTotal;
              monthlyQty[i] += quantity;
            }
          }
        }
        if (monthlyValue.reduce((a, b) => a + b) != 0) {
          ytdSalesDataList.add(
            ItemYTDSalesData(
              itemGroup: firstItemSale.itemSubGroup,
              aprValue: monthlyValue[0],
              mayValue: monthlyValue[1],
              junValue: monthlyValue[2],
              julValue: monthlyValue[3],
              augValue: monthlyValue[4],
              sepValue: monthlyValue[5],
              octValue: monthlyValue[6],
              novValue: monthlyValue[7],
              decValue: monthlyValue[8],
              janValue: monthlyValue[9],
              febValue: monthlyValue[10],
              marValue: monthlyValue[11],
              ytdTotalValue: monthlyValue.reduce((a, b) => a + b),
              ytdTotalAvg:
                  (monthlyQty.reduce((a, b) => a + b)) /
                  getCurrentFinancialMonthNumber(),
              q1Avg: (monthlyValue[0] + monthlyValue[1] + monthlyValue[2]) / 3,
              q2Avg: (monthlyValue[3] + monthlyValue[4] + monthlyValue[5]) / 3,
              q3Avg: (monthlyValue[6] + monthlyValue[7] + monthlyValue[8]) / 3,
              q4Avg:
                  (monthlyValue[9] + monthlyValue[10] + monthlyValue[11]) / 3,
            ),
          );
        }
        customerSales.clear();
      }
    }

    setState(() {
      ytdItemSalesList = ItemYTDSalesList(ytdData: ytdSalesDataList);
      YtdSalesBarChartData = true;
    });
  }

  int getLastTwoDigitsOfYear(DateTime date) {
    // Get the year from the DateTime object
    int year = date.year;

    // Extract the last two digits of the year using modulo operator
    int lastTwoDigits = year % 100;

    return lastTwoDigits;
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

  void loadMonthlySalesBarChartDataFromPieChart(int piechartIndex) {
    setState(() {
      selectedPiechartIndex = piechartIndex;
    });
    LoadDates();
    LoadAllQuarterFromToDates();

    List<MonthlySalesData> monthlyDataList = [];
    List<PrevYearMonthData> prevYearMonthDataList = [];

    prevYearMonthList = PrevYearMonthList(prevYearMonthData: []);

    /// PRECOMPUTE SALES BY MONTH
    Map<String, double> salesMonthMap = {};

    for (var s in filteredSales) {
      DateTime d = s.invoiceDate;

      int m = d.month;

      String monthName;

      if (m >= 4) {
        monthName = getMonthName(m);
      } else {
        monthName = getMonthName(m + 12);
      }

      double val = double.tryParse(s.rowTotal) ?? 0;

      salesMonthMap[monthName] = (salesMonthMap[monthName] ?? 0) + val;
    }

    if (piechartIndex == 1) {
      /// LAST MONTH MODE
      String monthName = getMonthName(lastMonthFromDate!.month);

      double monthlyTarget = 0;

      Iterable<SalesTargetList> targets = filteredTargets.where(
        (t) =>
            t.financialYear ==
            (currentDate!.month == 4 ? prevFinancialYear : financialYear),
      );

      for (var t in targets) {
        monthlyTarget += double.tryParse(t.getTargetForMonth(monthName)) ?? 0;
      }

      double monthlySales = salesMonthMap[monthName] ?? 0;

      monthlyDataList.add(
        MonthlySalesData(
          monthName: monthName,
          salesAmount: monthlySales,
          salesTarget: monthlyTarget,
        ),
      );

      if (currentDate!.month == 4) {
        prevYearMonthDataList.add(PrevYearMonthData(monthName: monthName));
      }

      prevYearMonthList = PrevYearMonthList(
        prevYearMonthData: prevYearMonthDataList,
      );
    } else {
      /// QUARTER MODE

      DateTime qrtFromDate = currentQuarterFromDate!;

      for (int i = 0; i < 3; i++) {
        String monthName = getMonthName(qrtFromDate.month);

        double monthlyTarget = 0;

        for (var t in filteredTargets) {
          if (t.financialYear != financialYear) continue;

          monthlyTarget += double.tryParse(t.getTargetForMonth(monthName)) ?? 0;
        }

        double monthlySales = salesMonthMap[monthName] ?? 0;

        monthlyDataList.add(
          MonthlySalesData(
            monthName: monthName,
            salesAmount: monthlySales,
            salesTarget: monthlyTarget,
          ),
        );

        qrtFromDate = addOneMonth(qrtFromDate);
      }

      prevYearMonthList = PrevYearMonthList(
        prevYearMonthData: prevYearMonthDataList,
      );
    }

    monthlySalesList = MonthlySalesList(monthlyData: monthlyDataList);
  }

  double calculateTotalForMonth(String month, List<Map<String, dynamic>> list) {
    return list.fold(0.0, (sum, item) {
      return sum +
          (item[month] != null ? double.parse(item[month].toString()) : 0.0);
    });
  }

  double calculateTotalForRep(
    String userName,
    String userLevel,
    Iterable<dynamic> iterableList,
  ) {
    double total = 0.0;

    for (var item in iterableList) {
      SalesTargetList target = item as SalesTargetList;

      /// Financial Year Filter
      if (target.financialYear != financialYear) continue;

      bool match = false;

      if (userLevel == "1") {
        match = target.salesRep == userName;
      } else if (userLevel == "2" || userLevel == "3") {
        match = target.salesManager == userName;
      } else {
        match = target.regionalManager == userName;
      }

      if (!match) continue;

      /// Sum All Months
      total += double.tryParse(target.april) ?? 0;
      total += double.tryParse(target.may) ?? 0;
      total += double.tryParse(target.june) ?? 0;
      total += double.tryParse(target.july) ?? 0;
      total += double.tryParse(target.aug) ?? 0;
      total += double.tryParse(target.sep) ?? 0;
      total += double.tryParse(target.oct) ?? 0;
      total += double.tryParse(target.nov) ?? 0;
      total += double.tryParse(target.dec) ?? 0;
      total += double.tryParse(target.jan) ?? 0;
      total += double.tryParse(target.feb) ?? 0;
      total += double.tryParse(target.mar) ?? 0;
    }

    return total;
  }

  Future<void> _loadMonthlyProductwiseSalesBarChartData(
    int monthIndex,
    List<SalesList> filteredSales,
  ) async {
    Map<String, double> salesMap = {};
    Map<String, double> targetMap = {};
    Map<String, String> nameMap = {};

    /// SALES MONTH RANGE
    var dateRange = getDateRangeForMonth(monthIndex);

    /// SALES FOR SELECTED MONTH
    List<SalesList> productSalesList = filteredSales.where((s) {
      return s.invoiceDate.isAtLeast(dateRange["start"]!) &&
          s.invoiceDate.isAtMost(dateRange["end"]!);
    }).toList();

    /// TARGET WINDOW (last 3 months)
    DateTime prevFrom = DateTime(currentDate!.year, currentDate!.month - 3, 1);
    DateTime prevTo = DateTime(currentDate!.year, currentDate!.month, 0);

    List<SalesList> curMthSalesTarget = filteredSales.where((s) {
      return s.invoiceDate.isAtLeast(prevFrom) &&
          s.invoiceDate.isAtMost(prevTo);
    }).toList();

    /// SALES AGGREGATION
    for (var s in productSalesList) {
      double val = double.tryParse(s.rowTotal) ?? 0;

      salesMap[s.code] = (salesMap[s.code] ?? 0) + val;

      nameMap[s.code] = s.description;
    }

    /// TARGET AGGREGATION
    for (var s in curMthSalesTarget) {
      double val = double.tryParse(s.rowTotal) ?? 0;

      targetMap[s.code] = (targetMap[s.code] ?? 0) + val;
    }

    /// BUILD RESULT
    List<ProductwiseData> result = [];

    salesMap.forEach((code, salesVal) {
      result.add(
        ProductwiseData(
          productCode: code,
          productName: nameMap[code] ?? "",
          salesAmount: salesVal,
          targetAmount: (targetMap[code] ?? 0) / 3,
        ),
      );
    });

    result.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    productwiseSalesList = ProductwiseSalesList(productData: result);
  }

  Future<void> _loadMonthlyProductGroupwiseSalesBarChartData(
    int monthIndex,
    List<SalesList> filteredSales,
  ) async {
    Map<String, double> salesMap = {};
    Map<String, double> targetMap = {};

    /// SALES MONTH RANGE
    var dateRange = getDateRangeForMonth(monthIndex);

    /// SALES FOR SELECTED MONTH
    List<SalesList> list = filteredSales.where((s) {
      return s.invoiceDate.isAtLeast(dateRange["start"]!) &&
          s.invoiceDate.isAtMost(dateRange["end"]!);
    }).toList();

    /// TARGET WINDOW (last 3 months)
    DateTime prevFrom = DateTime(currentDate!.year, currentDate!.month - 3, 1);
    DateTime prevTo = DateTime(currentDate!.year, currentDate!.month, 0);

    List<SalesList> targetList = filteredSales.where((s) {
      return s.invoiceDate.isAtLeast(prevFrom) &&
          s.invoiceDate.isAtMost(prevTo);
    }).toList();

    /// SALES AGGREGATION
    for (var s in list) {
      double val = double.tryParse(s.rowTotal) ?? 0;

      salesMap[s.itemSubGroup] = (salesMap[s.itemSubGroup] ?? 0) + val;
    }

    /// TARGET AGGREGATION
    for (var s in targetList) {
      double val = double.tryParse(s.rowTotal) ?? 0;

      targetMap[s.itemSubGroup] = (targetMap[s.itemSubGroup] ?? 0) + val;
    }

    /// BUILD RESULT
    List<ProductGroupwiseData> result = [];

    salesMap.forEach((grp, val) {
      result.add(
        ProductGroupwiseData(
          productGroupName: grp,
          salesAmount: val,
          targetAmount: (targetMap[grp] ?? 0) / 3,
        ),
      );
    });

    result.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    productGroupwiseSalesList = ProductGroupwiseSalesList(
      productGroupData: result,
    );
  }

  Future<void> _loadMonthlyCustomerWiseSalesBarChartData(
    int monthIndex,
    List<SalesList> filteredSales,
  ) async {
    Map<String, double> salesMap = {};
    Map<String, double> targetMap = {};
    Map<String, String> nameMap = {};

    /// SALES MONTH RANGE (current selection)
    var dateRange = getDateRangeForMonth(monthIndex);

    /// SALES FOR SELECTED MONTH
    List<SalesList> customerSalesList = filteredSales.where((s) {
      return s.invoiceDate.isAtLeast(dateRange["start"]!) &&
          s.invoiceDate.isAtMost(dateRange["end"]!);
    }).toList();

    /// TARGET RANGE (last 3 months window)
    DateTime prevFrom = DateTime(currentDate!.year, currentDate!.month - 3, 1);
    DateTime prevTo = DateTime(currentDate!.year, currentDate!.month, 0);

    /// TARGET SALES (ALREADY HIERARCHY FILTERED)
    List<SalesList> curMthSalesTarget = filteredSales.where((s) {
      return s.invoiceDate.isAtLeast(prevFrom) &&
          s.invoiceDate.isAtMost(prevTo);
    }).toList();

    /// SALES AGGREGATION
    for (var s in customerSalesList) {
      double val = double.tryParse(s.rowTotal) ?? 0;

      salesMap[s.customerCode] = (salesMap[s.customerCode] ?? 0) + val;

      nameMap[s.customerCode] = s.customerName;
    }

    /// TARGET AGGREGATION
    for (var s in curMthSalesTarget) {
      double val = double.tryParse(s.rowTotal) ?? 0;

      targetMap[s.customerCode] = (targetMap[s.customerCode] ?? 0) + val;
    }

    /// BUILD RESULT
    List<CustomerWiseData> result = [];

    salesMap.forEach((code, val) {
      result.add(
        CustomerWiseData(
          customerCode: code,
          customerName: nameMap[code] ?? "",
          saleAmount: val,
          targetAmount: (targetMap[code] ?? 0) / 3,
        ),
      );
    });

    result.sort((a, b) => b.saleAmount.compareTo(a.saleAmount));

    customerWiseSalesList = CustomerWiseSalesList(customerData: result);
  }

  Future<void> _loadMonthlyCustomerStateWiseSalesBarChartData(
    int monthIndex,
    List<SalesList> filteredSales,
  ) async {
    Map<String, double> salesMap = {};
    Map<String, double> targetMap = {};

    /// SALES MONTH RANGE (current selection)
    var dateRange = getDateRangeForMonth(monthIndex);

    /// SALES FOR SELECTED MONTH
    List<SalesList> customerSalesList = filteredSales.where((s) {
      return s.invoiceDate.isAtLeast(dateRange["start"]!) &&
          s.invoiceDate.isAtMost(dateRange["end"]!);
    }).toList();

    /// TARGET RANGE (previous 3 months)
    DateTime prevFrom = DateTime(currentDate!.year, currentDate!.month - 3, 1);
    DateTime prevTo = DateTime(currentDate!.year, currentDate!.month, 0);

    /// TARGET SALES (already hierarchy-filtered)
    List<SalesList> curMthSalesTarget = filteredSales.where((s) {
      return s.invoiceDate.isAtLeast(prevFrom) &&
          s.invoiceDate.isAtMost(prevTo);
    }).toList();

    /// SALES AGGREGATION
    for (var s in customerSalesList) {
      double val = double.tryParse(s.rowTotal) ?? 0;

      salesMap[s.customerState] = (salesMap[s.customerState] ?? 0) + val;
    }

    /// TARGET AGGREGATION
    for (var s in curMthSalesTarget) {
      double val = double.tryParse(s.rowTotal) ?? 0;

      targetMap[s.customerState] = (targetMap[s.customerState] ?? 0) + val;
    }

    /// BUILD RESULT
    List<CustomerStateWiseData> result = [];

    salesMap.forEach((state, val) {
      result.add(
        CustomerStateWiseData(
          stateName: state,
          saleAmount: val,
          targetAmount: (targetMap[state] ?? 0) / 3,
        ),
      );
    });

    result.sort((a, b) => b.saleAmount.compareTo(a.saleAmount));

    customerStateWiseSalesList = CustomerStateWiseSalesList(
      customerStateData: result,
    );
  }

  Future<void> _loadTSMSalesBarChartData(
    int monthIndex,
    List<SalesList> filteredSales,
    List<SalesTargetList> filteredTargets,
  ) async {
    List<TsmwiseData> tsmwiseDataList = [];

    /// MONTH RANGE
    var dateRange = getDateRangeForMonth(monthIndex);

    /// MONTH FILTER FOR SALES
    List<SalesList> tsmSalesList = filteredSales.where((target) {
      DateTime invoiceDate = target.invoiceDate;

      return invoiceDate.isAtLeast(dateRange["start"]!) &&
          invoiceDate.isAtMost(dateRange["end"]!);
    }).toList();

    /// MONTHS REQUIRED FOR TARGET
    List<String> monthsToInclude = getFinancialYearMonthsToInclude(monthIndex);

    /// TRIM TARGETS TO REQUIRED MONTHS
    var tsmSalesTargetList = filteredTargets.map((element) {
      Map<String, dynamic> filteredMap = {
        "financialYear": element.financialYear,
        "salesRepCode": element.salesRepCode,
        "salesRep": element.salesRep,
        "salesManager": element.salesManager,
        "regionalManager": element.regionalManager,
      };

      for (var month in monthsToInclude) {
        filteredMap[month] = element
            .getTargetForMonth(getFullMonthName(month))
            .toString();
      }

      return filteredMap;
    }).toList();

    /// CONVERT BACK TO OBJECT
    List<SalesTargetList> lstSalesTrgt = tsmSalesTargetList
        .map((item) => SalesTargetList.fromJson(item))
        .toList();

    /// -----------------------------------
    /// FAST SALES AGGREGATION (O(n))
    /// -----------------------------------

    Map<String, double> salesByTsm = {};

    for (var sale in tsmSalesList) {
      String rep = sale.salesRep;

      double amount = double.tryParse(sale.rowTotal) ?? 0;

      salesByTsm.update(rep, (value) => value + amount, ifAbsent: () => amount);
    }

    /// -----------------------------------

    for (var entry in salesByTsm.entries) {
      String tsmName = entry.key;
      double salesAmount = entry.value;

      double targetAmount = calculateTotalForRep(tsmName, "1", lstSalesTrgt);

      if (salesAmount + targetAmount > 0) {
        tsmwiseDataList.add(
          TsmwiseData(
            tsmName: tsmName,
            salesAmount: salesAmount,
            targetAmount: targetAmount,
          ),
        );
      }
    }

    /// SORT FOR CHART
    tsmwiseDataList.sort((a, b) => a.salesAmount.compareTo(b.salesAmount));

    /// FINAL LIST
    tsmwiseSalesList = TsmwiseSalesList(tsmwiseData: tsmwiseDataList);

    listOfTSM = tsmwiseDataList.map((e) => e.tsmName).toList();
  }

  Future<void> _loadASMSalesBarChartData(
    int monthIndex,
    List<SalesList> filteredSales,
    List<SalesTargetList> filteredTargets,
  ) async {
    List<AsmwiseData> asmwiseDataList = [];

    /// MONTH RANGE
    var dateRange = getDateRangeForMonth(monthIndex);

    /// MONTH FILTER FOR SALES
    List<SalesList> asmSalesList = filteredSales.where((target) {
      DateTime invoiceDate = target.invoiceDate;

      return invoiceDate.isAtLeast(dateRange["start"]!) &&
          invoiceDate.isAtMost(dateRange["end"]!);
    }).toList();

    /// TARGET MONTHS
    List<String> monthsToInclude = getFinancialYearMonthsToInclude(monthIndex);

    /// TRIM TARGETS TO MONTH RANGE
    var asmSalesTargetList = filteredTargets.map((element) {
      Map<String, dynamic> filteredMap = {
        "financialYear": element.financialYear,
        "salesRepCode": element.salesRepCode,
        "salesRep": element.salesRep,
        "salesManager": element.salesManager,
        "regionalManager": element.regionalManager,
      };

      for (var month in monthsToInclude) {
        filteredMap[month] = element
            .getTargetForMonth(getFullMonthName(month))
            .toString();
      }

      return filteredMap;
    }).toList();

    List<SalesTargetList> lstSalesTrgt = asmSalesTargetList
        .map((item) => SalesTargetList.fromJson(item))
        .toList();

    /// FAST AGGREGATION
    Map<String, double> salesByAsm = {};

    for (var sale in asmSalesList) {
      String asm = sale.salesManager;

      double amount = double.tryParse(sale.rowTotal) ?? 0;

      salesByAsm.update(asm, (value) => value + amount, ifAbsent: () => amount);
    }

    for (var entry in salesByAsm.entries) {
      String asmName = entry.key;
      double salesAmount = entry.value;

      double targetAmount = calculateTotalForRep(asmName, "2", lstSalesTrgt);

      if (salesAmount + targetAmount > 0) {
        asmwiseDataList.add(
          AsmwiseData(
            asmName: asmName,
            salesAmount: salesAmount,
            targetAmount: targetAmount,
          ),
        );
      }
    }

    asmwiseDataList.sort((a, b) => a.salesAmount.compareTo(b.salesAmount));

    asmwiseSalesList = AsmwiseSalesList(asmwiseData: asmwiseDataList);

    listOfASM = asmwiseDataList.map((e) => e.asmName).toList();
  }

  Future<void> _loadRSMSalesBarChartData(
    int monthIndex,
    List<SalesList> filteredSales,
    List<SalesTargetList> filteredTargets,
  ) async {
    List<RsmwiseData> rsmwiseDataList = [];

    /// MONTH RANGE
    var dateRange = getDateRangeForMonth(monthIndex);

    /// MONTH FILTER FOR SALES
    List<SalesList> rsmSalesList = filteredSales.where((target) {
      DateTime invoiceDate = target.invoiceDate;

      return invoiceDate.isAtLeast(dateRange["start"]!) &&
          invoiceDate.isAtMost(dateRange["end"]!);
    }).toList();

    /// TARGET MONTHS
    List<String> monthsToInclude = getFinancialYearMonthsToInclude(monthIndex);

    /// TRIM TARGETS TO MONTH RANGE
    var rsmSalesTargetList = filteredTargets.map((element) {
      Map<String, dynamic> filteredMap = {
        "financialYear": element.financialYear,
        "salesRepCode": element.salesRepCode,
        "salesRep": element.salesRep,
        "salesManager": element.salesManager,
        "regionalManager": element.regionalManager,
      };

      for (var month in monthsToInclude) {
        filteredMap[month] = element
            .getTargetForMonth(getFullMonthName(month))
            .toString();
      }

      return filteredMap;
    }).toList();

    List<SalesTargetList> lstSalesTrgt = rsmSalesTargetList
        .map((item) => SalesTargetList.fromJson(item))
        .toList();

    /// FAST AGGREGATION
    Map<String, double> salesByRsm = {};

    for (var sale in rsmSalesList) {
      String rsm = sale.regionalManager;

      double amount = double.tryParse(sale.rowTotal) ?? 0;

      salesByRsm.update(rsm, (value) => value + amount, ifAbsent: () => amount);
    }

    for (var entry in salesByRsm.entries) {
      String rsmName = entry.key;
      double salesAmount = entry.value;

      double targetAmount = calculateTotalForRep(rsmName, "4", lstSalesTrgt);

      if (salesAmount + targetAmount > 0) {
        rsmwiseDataList.add(
          RsmwiseData(
            rsmName: rsmName,
            salesAmount: salesAmount,
            targetAmount: targetAmount,
          ),
        );
      }
    }

    rsmwiseDataList.sort((a, b) => a.salesAmount.compareTo(b.salesAmount));

    rsmwiseSalesList = RsmwiseSalesList(rsmwiseData: rsmwiseDataList);

    listOfRSM = rsmwiseDataList.map((e) => e.rsmName).toList();
  }

  List<String> getFinancialYearMonthsToInclude(int monthIndex) {
    List<String> financialYearMonths = [
      'april',
      'may',
      'june',
      'july',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
      'jan',
      'feb',
      'mar',
    ];

    int currentMonth = DateTime.now().month;

    if (monthIndex == 0) {
      int fyIndex = (currentMonth >= 4) ? currentMonth - 4 : currentMonth + 8;

      return financialYearMonths.sublist(0, fyIndex + 1);
    }

    int fyIndex = (monthIndex >= 4) ? monthIndex - 4 : monthIndex + 8;

    return [financialYearMonths[fyIndex]];
  }

  Map<String, DateTime> getDateRangeForMonth(int monthIndex) {
    DateTime now = DateTime.now();

    // Determine financial year start
    int financialYearStart = now.month >= 4 ? now.year : now.year - 1;

    if (monthIndex == 0) {
      return {"start": currentMonthFromDate!, "end": currentDate!};
    }

    // Decide the correct year based on financial year logic
    int year = (monthIndex >= 4) ? financialYearStart : financialYearStart + 1;

    DateTime startDate = DateTime(year, monthIndex, 1);
    DateTime endDate = DateTime(year, monthIndex + 1, 0);

    return {"start": startDate, "end": endDate};
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    UserName = userName;
    await _loadUserList(
      userId,
      userJwtToken,
      userMailID,
      int.tryParse(userLevel) ?? 0,
    );
    await _loadUserListForFilter(
      userId,
      userJwtToken,
      userMailID,
      int.tryParse(userLevel) ?? 0,
    );
    await _loadSalesTarget(userName, userLevel);
    await _loadSalesWithLazyLoading(userName, userLevel);
    await _loadEachQtrValues();
    await _loadMonthlySalesBarChartData(filteredSales, filteredTargets);
    showDrillDownChart = true;
    touchedYearGraph = true;
    showProductSaleChart = true;
    if (UserLevel != "1") {
      await _loadTSMSalesBarChartData(0, filteredSales, filteredTargets);
      await _loadASMSalesBarChartData(0, filteredSales, filteredTargets);
      await _loadRSMSalesBarChartData(0, filteredSales, filteredTargets);
    }
    await _loadMonthlyProductGroupwiseSalesBarChartData(0, filteredSales);
    await _loadMonthlyProductwiseSalesBarChartData(0, filteredSales);
    await _loadMonthlyCustomerStateWiseSalesBarChartData(0, filteredSales);
    await _loadMonthlyCustomerWiseSalesBarChartData(0, filteredSales);
    setState(() {
      filterOptions = [listOfRSM, listOfASM, listOfTSM, []];
      savedFinanceReceivablesOptions = filterOptions
          .map((options) => List<bool>.filled(options.length, false))
          .toList();
      if (savedFinanceReceivablesOptionsTemp.isEmpty) {
        savedFinanceReceivablesOptions = filterOptions
            .map((options) => List<bool>.filled(options.length, false))
            .toList();
      } else {
        savedFinanceReceivablesOptions = savedFinanceReceivablesOptionsTemp;
      }
      chartDataLoaded = true;
    });
  }

  void resetSalesLists() {
    ytdSalesList = YTDSalesList(ytdData: []);
    ytdItemSalesList = ItemYTDSalesList(ytdData: []);
    monthlySalesList = MonthlySalesList(monthlyData: []);
    prevMonthlySalesList = MonthlySalesList(monthlyData: []);
    productwiseSalesList = ProductwiseSalesList(productData: []);
    productGroupwiseSalesList = ProductGroupwiseSalesList(productGroupData: []);

    customerWiseSalesList = CustomerWiseSalesList(customerData: []);

    customerStateWiseSalesList = CustomerStateWiseSalesList(
      customerStateData: [],
    );

    prevYearMonthList = PrevYearMonthList(prevYearMonthData: []);

    tsmwiseSalesList = TsmwiseSalesList(tsmwiseData: []);

    asmwiseSalesList = AsmwiseSalesList(asmwiseData: []);

    rsmwiseSalesList = RsmwiseSalesList(rsmwiseData: []);

    listOfRSM.clear();
    listOfASM.clear();
    listOfTSM.clear();
  }

  Future<void> removeFilter() async {
    resetSalesLists();

    touchedMonthIndex = 0;

    touchedRegionalManager = "";
    touchedSalesManager = "";
    touchedSalesRep = "";

    touchedCustomer = "";
    touchedProduct = "";
    touchedProductGroup = "";
    touchedState = "";

    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;

    for (var options in allCategoriesState.values) {
      options.updateAll((key, value) => false);
    }

    allCategoriesState.clear();

    setState(() {
      chartDataLoaded = false;
    });

    // Wait until everything is loaded again
    sales = await _applyUserFilter(_allSales, UserName, UserLevel);
    monthlySales = {};
    buildFilteredLists();
    await _updateMonthlySales(filteredSales);
    await loadDataWithFilter(0, "", "", "", "", "", "", "");

    // Rebuild checkbox states
    filterOptions = [listOfRSM, listOfASM, listOfTSM, []];

    savedFinanceReceivablesOptions = filterOptions
        .map((e) => List<bool>.filled(e.length, false))
        .toList();

    savedFinanceReceivablesOptionsTemp = filterOptions
        .map((e) => List<bool>.filled(e.length, false))
        .toList();

    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataWithFilter(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String stateName,
    String customerCode,
    String productGroupCode,
    String productCode,
  ) async {
    setState(() {
      chartDataLoaded = false;
    });
    bool showASMChart = true;
    bool showTSMChart = true;

    if (!hasASMChildren(regionalManager)) {
      showASMChart = false;
      showTSMChart = false;
    }

    if (!hasTSMChildren(salesManager)) {
      showTSMChart = false;
    }

    clearVariablesForFilter();
    LoadDates();
    LoadAllQuarterFromToDates();

    showDrillDownChart = true;
    touchedYearGraph = true;
    showProductSaleChart = true;

    /// Filter once
    final filteredSales = filterSalesList(
      sales,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      customerCode: customerCode,
      productGroupCode: productGroupCode,
      productCode: productCode,
    );

    final filteredTargets = filterSalesTargetList(
      salesTarget,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
    );

    List<Future> futures = [];

    if (UserLevel != "1") {
      if (showTSMChart) {
        futures.add(
          _loadTSMSalesBarChartData(monthIndex, filteredSales, filteredTargets),
        );
      } else {
        tsmwiseSalesList = TsmwiseSalesList(tsmwiseData: []);
      }

      if (showASMChart) {
        futures.add(
          _loadASMSalesBarChartData(monthIndex, filteredSales, filteredTargets),
        );
      } else {
        asmwiseSalesList = AsmwiseSalesList(asmwiseData: []);
      }

      futures.add(
        _loadRSMSalesBarChartData(monthIndex, filteredSales, filteredTargets),
      );
    }

    futures.addAll([
      _loadMonthlySalesBarChartData(filteredSales, filteredTargets),
      _loadMonthlyProductGroupwiseSalesBarChartData(monthIndex, filteredSales),
      _loadMonthlyProductwiseSalesBarChartData(monthIndex, filteredSales),
      _loadMonthlyCustomerStateWiseSalesBarChartData(monthIndex, filteredSales),
      _loadMonthlyCustomerWiseSalesBarChartData(monthIndex, filteredSales),
    ]);

    await Future.wait(futures);
    filterOptions = [listOfRSM, listOfASM, listOfTSM, []];

    savedFinanceReceivablesOptions = filterOptions
        .map((e) => List<bool>.filled(e.length, false))
        .toList();

    setState(() {
      chartDataLoaded = true;
    });
  }

  bool hasASMChildren(String regionalManager) {
    if (regionalManager.isEmpty) return true;

    int menuId = usersListForFilter
        .firstWhere(
          (e) => e.menuName == regionalManager,
          orElse: () => Users(
            menuId: -1,
            menuName: '',
            subMenuId: -1,
            parentMenuId: -1,
            userLevel: -1,
          ),
        )
        .menuId;

    if (menuId == -1) return false;

    return usersListForFilter.any((e) => e.parentMenuId == menuId);
  }

  bool hasTSMChildren(String salesManager) {
    if (salesManager.isEmpty) return true;

    int menuId = usersListForFilter
        .firstWhere(
          (e) => e.menuName == salesManager,
          orElse: () => Users(
            menuId: -1,
            menuName: '',
            subMenuId: -1,
            parentMenuId: -1,
            userLevel: -1,
          ),
        )
        .menuId;

    if (menuId == -1) return false;

    return usersListForFilter.any((e) => e.parentMenuId == menuId);
  }

  void LoadDates() {
    currentDate = DateTime.now();
    currentMonthFromDate = DateTime(currentDate!.year, currentDate!.month, 1);
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

  Future<void> generateSalesExcel(MonthlySalesList monthlySalesList) async {
    await reportService.generateExcel(
      sheetName: 'MonthWiseSalesAnalysis',
      headers: [
        'Month',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: monthlySalesList.monthlyData
          .map(
            (monthlyData) => [
              monthlyData.monthName,
              monthlyData.salesTarget,
              monthlyData.salesAmount,
              monthlyData.salesTarget != 0
                  ? ((monthlyData.salesAmount / monthlyData.salesTarget) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              monthlyData.salesAmount - monthlyData.salesTarget,
            ],
          )
          .toList(),
      fileName: 'monthly_sales_report.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - MonthWise Sales Analysis',
    );
  }

  Future<void> generateSalesPDF(MonthlySalesList monthlySalesList) async {
    await reportService.generatePDF(
      title: 'MonthWiseSalesAnalysis',
      headers: [
        'Month',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: monthlySalesList.monthlyData
          .map(
            (monthlyData) => [
              monthlyData.monthName,
              monthlyData.salesTarget,
              monthlyData.salesAmount,
              monthlyData.salesTarget != 0
                  ? ((monthlyData.salesAmount / monthlyData.salesTarget) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              monthlyData.salesAmount - monthlyData.salesTarget,
            ],
          )
          .toList(),
      fileName: 'monthly_sales_report.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateRsmSalesExcel(RsmwiseSalesList rsmwiseSalesList) async {
    await reportService.generateExcel(
      sheetName: 'RSMSalesAnalysis',
      headers: [
        'RSM Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: rsmwiseSalesList.rsmwiseData
          .map(
            (rsmData) => [
              rsmData.rsmName,
              rsmData.targetAmount,
              rsmData.salesAmount,
              rsmData.targetAmount != 0
                  ? ((rsmData.salesAmount / rsmData.targetAmount) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              rsmData.salesAmount - rsmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'regional_manager_sales.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - RSM Sales Analysis',
    );
  }

  Future<void> generateRsmSalesPDF(RsmwiseSalesList rsmwiseSalesList) async {
    await reportService.generatePDF(
      title: 'RSMSalesAnalysis',
      headers: [
        'RSM Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: rsmwiseSalesList.rsmwiseData
          .map(
            (rsmData) => [
              rsmData.rsmName,
              rsmData.targetAmount,
              rsmData.salesAmount,
              rsmData.targetAmount != 0
                  ? ((rsmData.salesAmount / rsmData.targetAmount) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              rsmData.salesAmount - rsmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'regional_manager_sales.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateAsmSalesExcel(AsmwiseSalesList asmwiseSalesList) async {
    await reportService.generateExcel(
      sheetName: 'ASMSalesAnalysis',
      headers: [
        'ASM Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: asmwiseSalesList.asmwiseData
          .map(
            (asmData) => [
              asmData.asmName,
              asmData.targetAmount,
              asmData.salesAmount,
              asmData.targetAmount != 0
                  ? ((asmData.salesAmount / asmData.targetAmount) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              asmData.salesAmount - asmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'asm_sales.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - ASM Sales Analysis',
    );
  }

  Future<void> generateAsmSalesPDF(AsmwiseSalesList asmwiseSalesList) async {
    await reportService.generatePDF(
      title: 'ASMSalesAnalysis',
      headers: [
        'ASM Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: asmwiseSalesList.asmwiseData
          .map(
            (asmData) => [
              asmData.asmName,
              asmData.targetAmount,
              asmData.salesAmount,
              asmData.targetAmount != 0
                  ? ((asmData.salesAmount / asmData.targetAmount) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              asmData.salesAmount - asmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'asm_sales.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateTsmSalesExcel(TsmwiseSalesList tsmwiseSalesList) async {
    await reportService.generateExcel(
      sheetName: 'TSMSalesAnalysis',
      headers: [
        'TSM Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: tsmwiseSalesList.tsmwiseData
          .map(
            (tsmData) => [
              tsmData.tsmName,
              tsmData.targetAmount,
              tsmData.salesAmount,
              tsmData.targetAmount != 0
                  ? ((tsmData.salesAmount / tsmData.targetAmount) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              tsmData.salesAmount - tsmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'tsm_sales.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - TSM Sales Analysis',
    );
  }

  Future<void> generateTsmSalesPDF(TsmwiseSalesList tsmwiseSalesList) async {
    await reportService.generatePDF(
      title: 'TSMSalesAnalysis',
      headers: [
        'TSM Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: tsmwiseSalesList.tsmwiseData
          .map(
            (tsmData) => [
              tsmData.tsmName,
              tsmData.targetAmount,
              tsmData.salesAmount,
              tsmData.targetAmount != 0
                  ? ((tsmData.salesAmount / tsmData.targetAmount) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              tsmData.salesAmount - tsmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'tsm_sales.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateCustomerStateSalesExcel(
    CustomerStateWiseSalesList customerStateWiseSalesList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'CustomerStateWiseSalesAnalysis',
      headers: [
        'State Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: customerStateWiseSalesList.customerStateData
          .map(
            (stateData) => [
              stateData.stateName,
              stateData.targetAmount,
              stateData.saleAmount,
              stateData.targetAmount != 0
                  ? ((stateData.saleAmount / stateData.targetAmount) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              stateData.saleAmount - stateData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'customer_state_wise_sales.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - Customer State Wise Sales Analysis',
    );
  }

  Future<void> generateCustomerStateSalesPDF(
    CustomerStateWiseSalesList customerStateWiseSalesList,
  ) async {
    await reportService.generatePDF(
      title: 'CustomerStateWiseSalesAnalysis',
      headers: [
        'State Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: customerStateWiseSalesList.customerStateData
          .map(
            (stateData) => [
              stateData.stateName,
              stateData.targetAmount,
              stateData.saleAmount,
              stateData.targetAmount != 0
                  ? ((stateData.saleAmount / stateData.targetAmount) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              stateData.saleAmount - stateData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'customer_state_wise_sales.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateCustomerSalesExcel(
    CustomerWiseSalesList customerWiseSalesList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'CustomerWiseSalesAnalysis',
      headers: [
        'State Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: customerWiseSalesList.customerData
          .map(
            (customerData) => [
              customerData.customerName,
              customerData.targetAmount,
              customerData.saleAmount,
              customerData.targetAmount != 0
                  ? ((customerData.saleAmount / customerData.targetAmount) *
                            100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              customerData.saleAmount - customerData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'customer_wise_sales.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - Customer Wise Sales Analysis',
    );
  }

  Future<void> generateCustomerSalesPDF(
    CustomerWiseSalesList customerWiseSalesList,
  ) async {
    await reportService.generatePDF(
      title: 'CustomerWiseSalesAnalysis',
      headers: [
        'State Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: customerWiseSalesList.customerData
          .map(
            (customerData) => [
              customerData.customerName,
              customerData.targetAmount,
              customerData.saleAmount,
              customerData.targetAmount != 0
                  ? ((customerData.saleAmount / customerData.targetAmount) *
                            100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              customerData.saleAmount - customerData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'customer_wise_sales.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateItemGroupSalesExcel() async {
    if (ytdItemSalesList.ytdData.isEmpty) {
      await _loadMonthlyItemSalesData();
    }

    await reportService.generateExcel(
      sheetName: 'ItemGroupWiseSalesAnalysis',
      headers: [
        'Product Group',
        'April',
        'May',
        'Jun',
        'Q1 Avg',
        'Jul',
        'Aug',
        'Sep',
        'Q2 Avg',
        'Oct',
        'Nov',
        'Dec',
        'Q3 Avg',
        'Jan',
        'Feb',
        'Mar',
        'Q4 Avg',
        'YTD Total',
        'YTD Avg',
      ],
      rows: ytdItemSalesList.ytdData
          .map(
            (groupData) => [
              groupData.itemGroup,
              groupData.marValue,
              groupData.aprValue,
              groupData.junValue,
              groupData.q1Avg,
              groupData.julValue,
              groupData.augValue,
              groupData.sepValue,
              groupData.q2Avg,
              groupData.octValue,
              groupData.novValue,
              groupData.decValue,
              groupData.q3Avg,
              groupData.janValue,
              groupData.febValue,
              groupData.marValue,
              groupData.q4Avg,
              groupData.ytdTotalValue,
              groupData.ytdTotalAvg,
            ],
          )
          .toList(),
      fileName: 'item_group_sales.xlsx',
      amountColumns: [
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
      ],
      addTotalRow: true,
      reportTitle: 'Sales - Item Group Wise Sales Analysis',
    );
  }

  Future<void> generateItemGroupSalesPDF() async {
    if (ytdItemSalesList.ytdData.isEmpty) {
      await _loadMonthlyItemSalesData();
    }
    await reportService.generatePDF(
      title: 'ItemGroupWiseSalesAnalysis',
      headers: [
        'Product Group',
        'April',
        'May',
        'Jun',
        'Q1 Avg',
        'Jul',
        'Aug',
        'Sep',
        'Q2 Avg',
        'Oct',
        'Nov',
        'Dec',
        'Q3 Avg',
        'Jan',
        'Feb',
        'Mar',
        'Q4 Avg',
        'YTD Total',
        'YTD Avg',
      ],
      rows: ytdItemSalesList.ytdData
          .map(
            (groupData) => [
              groupData.itemGroup,
              groupData.marValue,
              groupData.aprValue,
              groupData.junValue,
              groupData.q1Avg,
              groupData.julValue,
              groupData.augValue,
              groupData.sepValue,
              groupData.q2Avg,
              groupData.octValue,
              groupData.novValue,
              groupData.decValue,
              groupData.q3Avg,
              groupData.janValue,
              groupData.febValue,
              groupData.marValue,
              groupData.q4Avg,
              groupData.ytdTotalValue,
              groupData.ytdTotalAvg,
            ],
          )
          .toList(),
      fileName: 'item_group_sales.pdf',
      amountColumns: [
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
      ],
    );
  }

  Future<void> generateItemSalesExcel(
    ProductwiseSalesList productwiseSalesList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ItemWiseSalesAnalysis',
      headers: [
        'Product Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: productwiseSalesList.productData
          .map(
            (itemData) => [
              itemData.productName,
              itemData.targetAmount,
              itemData.salesAmount,
              itemData.targetAmount != 0
                  ? ((itemData.salesAmount / itemData.targetAmount) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              itemData.salesAmount - itemData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'item_sales_report.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - Item Wise Sales Analysis',
    );
  }

  Future<void> generateItemSalesPDF(
    ProductwiseSalesList productwiseSalesList,
  ) async {
    await reportService.generatePDF(
      title: 'ItemWiseSalesAnalysis',
      headers: [
        'Product Name',
        'Sales Target',
        'Sales Amount',
        'Percentage',
        'Difference',
      ],
      rows: productwiseSalesList.productData
          .map(
            (itemData) => [
              itemData.productName,
              itemData.targetAmount,
              itemData.salesAmount,
              itemData.targetAmount != 0
                  ? ((itemData.salesAmount / itemData.targetAmount) * 100)
                        .ceil()
                        .toStringAsFixed(0)
                  : 0,
              itemData.salesAmount - itemData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'item_sales_report.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateSalesAnalysisYTDExcel() async {
    if (ytdSalesList.ytdData.isEmpty) {
      await _loadYtdSalesBarChartData();
    }
    await reportService.generateExcel(
      sheetName: 'YTDSalesAnalysis',
      headers: [
        'Customer Name',
        'Sales Manager',
        'Sales Representative',
        'Product Category',
        'Product Name',
        'Apr Qty',
        'Apr Value',
        'May Qty',
        'May Value',
        'Jun Qty',
        'Jun Value',
        'Jul Qty',
        'Jul Value',
        'Aug Qty',
        'Aug Value',
        'Sep Qty',
        'Sep Value',
        'Oct Qty',
        'Oct Value',
        'Nov Qty',
        'Nov Value',
        'Dec Qty',
        'Dec Value',
        'Jan Qty',
        'Jan Value',
        'Feb Qty',
        'Feb Value',
        'Mar Qty',
        'Mar Value',
        'YTD Total Value',
        'YTD Total Qty',
      ],
      rows: ytdSalesList.ytdData
          .map(
            (ytdData) => [
              ytdData.customerName,
              ytdData.salesManager,
              ytdData.salesRep,
              ytdData.itemSubGroup,
              ytdData.itemName,
              ytdData.aprQty,
              ytdData.aprValue,
              ytdData.mayQty,
              ytdData.mayValue,
              ytdData.junQty,
              ytdData.junValue,
              ytdData.julQty,
              ytdData.julValue,
              ytdData.augQty,
              ytdData.augValue,
              ytdData.sepQty,
              ytdData.sepValue,
              ytdData.octQty,
              ytdData.octValue,
              ytdData.novQty,
              ytdData.novValue,
              ytdData.decQty,
              ytdData.decValue,
              ytdData.janQty,
              ytdData.janValue,
              ytdData.febQty,
              ytdData.febValue,
              ytdData.marQty,
              ytdData.marValue,
              ytdData.ytdTotalValue,
              ytdData.ytdTotalQty,
            ],
          )
          .toList(),
      fileName: 'sales_analysis_ytd_report.xlsx',
      amountColumns: [
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
      ],
      addTotalRow: true,
      reportTitle: 'Sales - Sales Analysis(YTD)',
    );
  }

  int getCurrentFinancialMonthNumber() {
    DateTime now = DateTime.now();
    int currentMonth = now.month;

    const int financialYearStartMonth = 4; // April

    int financialMonthNumber;

    if (currentMonth >= financialYearStartMonth) {
      financialMonthNumber = currentMonth - financialYearStartMonth + 1;
    } else {
      financialMonthNumber = 12 - (financialYearStartMonth - currentMonth) + 1;
    }

    return financialMonthNumber;
  }

  Future<void> generateSalesAnalysisQuarterDataYTDExcel() async {
    if (ytdSalesList.ytdData.isEmpty) {
      await _loadYtdSalesBarChartData();
    }
    await reportService.generateExcel(
      sheetName: 'QuarterlySalesAnalysis',
      headers: [
        'Customer Name',
        'Sales Manager',
        'Sales Representative',
        'Product Category',
        'Product Name',
        'Q1 Avg Qty',
        'Q1 Avg Value',
        'Q2 Avg Qty',
        'Q2 Avg Value',
        'Q3 Avg Qty',
        'Q3 Avg Value',
        'Q4 Avg Qty',
        'Q4 Avg Value',
        'YTD Avg Qty',
        'YTD Avg Value',
        'YTD Total Qty',
        'YTD Total Value',
      ],
      rows: ytdSalesList.ytdData
          .map(
            (ytdData) => [
              ytdData.customerName,
              ytdData.salesManager,
              ytdData.salesRep,
              ytdData.itemSubGroup,
              ytdData.itemName,
              ((ytdData.aprQty + ytdData.mayQty + ytdData.junQty) / 3),
              ((ytdData.aprValue + ytdData.mayValue + ytdData.junValue) / 3),
              ((ytdData.julQty + ytdData.augQty + ytdData.sepQty) / 3),
              ((ytdData.julValue + ytdData.augValue + ytdData.sepValue) / 3),
              ((ytdData.octQty + ytdData.novQty + ytdData.decQty) / 3),
              ((ytdData.octValue + ytdData.novValue + ytdData.decValue) / 3),
              ((ytdData.janQty + ytdData.febQty + ytdData.marQty) / 3),
              ((ytdData.janValue + ytdData.febValue + ytdData.marValue) / 3),
              (ytdData.ytdTotalQty / getCurrentFinancialMonthNumber()),
              (ytdData.ytdTotalValue / getCurrentFinancialMonthNumber()),
              ytdData.ytdTotalQty,
              ytdData.ytdTotalValue,
            ],
          )
          .toList(),
      fileName: 'sales_analysis_quarterData.xlsx',
      amountColumns: [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
      addTotalRow: true,
      reportTitle: 'Sales - Sales Analysis(Quarterly)',
    );
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _monthlySalesHorizontalController = ScrollController();
  final ScrollController _regionalManagerHorizontalController =
      ScrollController();
  final ScrollController _salesManagerHorizontalController = ScrollController();
  final ScrollController _salesPersonHorizontalController = ScrollController();
  final ScrollController _customerStateWiseHorizontalController =
      ScrollController();
  final ScrollController _customerSalesHorizontalController =
      ScrollController();
  final ScrollController _itemGroupWiseHorizontalController =
      ScrollController();
  final ScrollController _itemWiseHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    chartDataLoaded = false;
    YtdSalesBarChartData = false;
    clearVariables();
    LoadDates();
    LoadAllQuarterFromToDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
      toDateFilter = currentDate;
      fromDateFilter = fiscalYearStartDate;
    }

    filterOptions = [listOfRSM, listOfASM, listOfTSM, []];

    selectedFinanceReceivablesOptions = filterOptions
        .map((options) => List<bool>.filled(options.length, false))
        .toList();

    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;
      YtdSalesBarChartData = false;
      SalesGoal = 0;
      LastMonthSales = 0;
      LastMonthTarget = 0;
      CurrentQtrSales = 0;
      CurrentQtrTarget = 0;
      YtdSales = 0;
      YtdTarget = 0;
      Q1Sales = 0;
      Q1Target = 0;
      Q1Diff = 0;
      Q1Percentage = 0;
      Q1SalesStr = "";
      Q1TargetStr = "";
      Q1DiffStr = "";
      Q1PercentageStr = "";
      Q2Sales = 0;
      Q2Target = 0;
      Q2Diff = 0;
      Q2Percentage = 0;
      Q2SalesStr = "";
      Q2TargetStr = "";
      Q2DiffStr = "";
      Q2PercentageStr = "";
      Q3Sales = 0;
      Q3Target = 0;
      Q3Diff = 0;
      Q3Percentage = 0;
      Q3SalesStr = "";
      Q3TargetStr = "";
      Q3DiffStr = "";
      Q3PercentageStr = "";
      Q4Sales = 0;
      Q4Target = 0;
      Q4Diff = 0;
      Q4Percentage = 0;
      Q4SalesStr = "";
      Q4TargetStr = "";
      Q4DiffStr = "";
      Q4PercentageStr = "";
      Q1Average = 0;
      Q1AverageStr = "";
      Q2Average = 0;
      Q2AverageStr = "";
      Q3Average = 0;
      Q3AverageStr = "";
      Q4Average = 0;
      Q4AverageStr = "";
      monthlySalesList = MonthlySalesList(monthlyData: []);
      prevMonthlySalesList = MonthlySalesList(monthlyData: []);
      productwiseSalesList = ProductwiseSalesList(productData: []);
      customerWiseSalesList = CustomerWiseSalesList(customerData: []);
      prevYearMonthList = PrevYearMonthList(prevYearMonthData: []);
      tsmwiseSalesList = TsmwiseSalesList(tsmwiseData: []);
      asmwiseSalesList = AsmwiseSalesList(asmwiseData: []);
      rsmwiseSalesList = RsmwiseSalesList(rsmwiseData: []);
      customerStateWiseSalesList = CustomerStateWiseSalesList(
        customerStateData: [],
      );
      productGroupwiseSalesList = ProductGroupwiseSalesList(
        productGroupData: [],
      );
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoaded = false;
      YtdSalesBarChartData = false;

      productwiseSalesList = ProductwiseSalesList(productData: []);
      customerWiseSalesList = CustomerWiseSalesList(customerData: []);
      tsmwiseSalesList = TsmwiseSalesList(tsmwiseData: []);
      asmwiseSalesList = AsmwiseSalesList(asmwiseData: []);
      rsmwiseSalesList = RsmwiseSalesList(rsmwiseData: []);
      customerStateWiseSalesList = CustomerStateWiseSalesList(
        customerStateData: [],
      );
      productGroupwiseSalesList = ProductGroupwiseSalesList(
        productGroupData: [],
      );
    });
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _monthlySalesHorizontalController.dispose();
    _regionalManagerHorizontalController.dispose();
    _salesManagerHorizontalController.dispose();
    _salesPersonHorizontalController.dispose();
    _customerStateWiseHorizontalController.dispose();
    _customerSalesHorizontalController.dispose();
    _itemGroupWiseHorizontalController.dispose();
    _itemWiseHorizontalController.dispose();
    clearVariables();
    _longPressGestureRecognizer.dispose();
    ytdSalesList = YTDSalesList(ytdData: []);
    ytdItemSalesList = ItemYTDSalesList(ytdData: []);
    monthlySalesList = MonthlySalesList(monthlyData: []);
    prevMonthlySalesList = MonthlySalesList(monthlyData: []);
    productwiseSalesList = ProductwiseSalesList(productData: []);
    customerWiseSalesList = CustomerWiseSalesList(customerData: []);
    prevYearMonthList = PrevYearMonthList(prevYearMonthData: []);
    tsmwiseSalesList = TsmwiseSalesList(tsmwiseData: []);
    asmwiseSalesList = AsmwiseSalesList(asmwiseData: []);
    rsmwiseSalesList = RsmwiseSalesList(rsmwiseData: []);
    customerStateWiseSalesList = CustomerStateWiseSalesList(
      customerStateData: [],
    );
    productGroupwiseSalesList = ProductGroupwiseSalesList(productGroupData: []);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final screenWidth = media.width;
    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
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
                        dateFilterFlag
                            ? Text(
                                "${formatDateString(fromDateFilter!)} - ${formatDateString(toDateFilter!)}",
                              )
                            : Text(
                                "${formatDateString(fiscalYearStartDate!)} - ${formatDateString(currentDate!)}",
                              ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            showFilterBottomSheet(context);
                          },
                          icon: const Icon(Icons.filter_alt_outlined),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Sales Analysis',
                    menuItems: [
                      PopupMenuItem(
                        onTap: () async {
                          showLoaderDialog(context);
                          generateSalesAnalysisYTDExcel();
                          if (YtdSalesBarChartData == true) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],

                    child: Column(
                      children: [
                        _buildLazyLoadIndicator(),
                        SizedBox(
                          height: screenWidth < 600 ? 240 : 300,
                          child: Stack(
                            children: [
                              Center(
                                child: CircularPercentIndicator(
                                  arcType: ArcType.HALF,
                                  radius: 100.0,
                                  lineWidth: 32.0,
                                  animation: true,
                                  percent: CurrentMonthSalesPercentage / 100,
                                  center: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 30.0,
                                        ),
                                        child: Text(
                                          CurrentMonthSalesPercentageStr,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        CurrentMonthSalesStr,
                                        style: const TextStyle(fontSize: 14.0),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "${getMonthName(currentDate!.month)} Goal - $SalesGoalStr",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  circularStrokeCap: CircularStrokeCap.butt,
                                  progressColor: Colors.red,
                                  arcBackgroundColor: Colors.grey.shade200,
                                ),
                              ),
                              Positioned.fill(
                                top: screenWidth < 600 ? 125 : 150,
                                left: 0,
                                child: SizedBox(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isMobile =
                                          constraints.maxWidth < 360;

                                      return isMobile
                                          ? Wrap(
                                              alignment: WrapAlignment.center,
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                        right: 4.0,
                                                      ),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {});
                                                    },
                                                    child: CircularPercentIndicator(
                                                      arcType: ArcType.HALF,
                                                      radius: 45.0,
                                                      lineWidth: 16.0,
                                                      animation: true,
                                                      percent:
                                                          LastMonthPercentage /
                                                          100,
                                                      center: Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 26,
                                                          ),
                                                          Text(
                                                            LastMonthPercentageStr,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  touchedMonthGoals
                                                                  ? 13.0
                                                                  : 12.0,
                                                              color:
                                                                  touchedMonthGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          Text(
                                                            LastMonthSalesStr,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  touchedMonthGoals
                                                                  ? 11.0
                                                                  : 10.0,
                                                              color:
                                                                  touchedMonthGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Center(
                                                            child: Text(
                                                              "${getMonthName(currentDate!.month - 1)} Sales \n($LastMonthTargetStr)",
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize:
                                                                    touchedMonthGoals
                                                                    ? 11.0
                                                                    : 10.0,
                                                                color:
                                                                    touchedMonthGoals
                                                                    ? Colors
                                                                          .cyan
                                                                    : Colors
                                                                          .black,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      curve: Curves.linear,
                                                      circularStrokeCap:
                                                          CircularStrokeCap
                                                              .butt,
                                                      progressColor: Colors.red,
                                                      arcBackgroundColor:
                                                          Colors.grey.shade200,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    4.0,
                                                  ),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {});
                                                    },
                                                    child: CircularPercentIndicator(
                                                      arcType: ArcType.HALF,
                                                      radius: 45.0,
                                                      lineWidth: 16.0,
                                                      animation: true,
                                                      percent:
                                                          CurrentQtrPercentage /
                                                          100,
                                                      center: Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 26,
                                                          ),
                                                          Text(
                                                            CurrentQtrPercentageStr,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  touchedQuarterGoals
                                                                  ? 13.0
                                                                  : 12.0,
                                                              color:
                                                                  touchedQuarterGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          Text(
                                                            CurrentQtrSalesStr,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  touchedQuarterGoals
                                                                  ? 11.0
                                                                  : 10.0,
                                                              color:
                                                                  touchedQuarterGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            "Q$currentQuarter Sales \n($CurrentQtrTargetStr)",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  touchedQuarterGoals
                                                                  ? 11.0
                                                                  : 10.0,
                                                              color:
                                                                  touchedQuarterGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      curve: Curves.linear,
                                                      circularStrokeCap:
                                                          CircularStrokeCap
                                                              .butt,
                                                      progressColor:
                                                          Colors.orange,
                                                      arcBackgroundColor:
                                                          Colors.grey.shade200,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    4.0,
                                                  ),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {});
                                                    },
                                                    child: CircularPercentIndicator(
                                                      arcType: ArcType.HALF,
                                                      radius: 45.0,
                                                      lineWidth: 16.0,
                                                      animation: true,
                                                      percent:
                                                          YtdPercentage / 100,
                                                      center: Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 26,
                                                          ),
                                                          Text(
                                                            YtdPercentageStr,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  touchedYTDGoals
                                                                  ? 13.0
                                                                  : 12.0,
                                                              color:
                                                                  touchedYTDGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          Text(
                                                            YtdSalesStr,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  touchedYTDGoals
                                                                  ? 11.0
                                                                  : 10.0,
                                                              color:
                                                                  touchedYTDGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            "YTD \n($YtdTargetStr)",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  touchedYTDGoals
                                                                  ? 11.0
                                                                  : 10.0,
                                                              color:
                                                                  touchedYTDGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      curve: Curves.linear,
                                                      circularStrokeCap:
                                                          CircularStrokeCap
                                                              .butt,
                                                      progressColor:
                                                          Colors.green,
                                                      arcBackgroundColor:
                                                          Colors.grey.shade200,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                        right: 4.0,
                                                      ),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {});
                                                    },
                                                    child: CircularPercentIndicator(
                                                      arcType: ArcType.HALF,
                                                      radius: 55.0,
                                                      lineWidth: 20.0,
                                                      animation: true,
                                                      percent:
                                                          LastMonthPercentage /
                                                          100,
                                                      center: Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 30,
                                                          ),
                                                          Text(
                                                            LastMonthPercentageStr,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  touchedMonthGoals
                                                                  ? 13.0
                                                                  : 12.0,
                                                              color:
                                                                  touchedMonthGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          Text(
                                                            LastMonthSalesStr,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  touchedMonthGoals
                                                                  ? 11.0
                                                                  : 10.0,
                                                              color:
                                                                  touchedMonthGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Center(
                                                            child: Text(
                                                              "${getMonthName(currentDate!.month - 1)} Sales \n($LastMonthTargetStr)",
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize:
                                                                    touchedMonthGoals
                                                                    ? 11.0
                                                                    : 10.0,
                                                                color:
                                                                    touchedMonthGoals
                                                                    ? Colors
                                                                          .cyan
                                                                    : Colors
                                                                          .black,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      curve: Curves.linear,
                                                      circularStrokeCap:
                                                          CircularStrokeCap
                                                              .butt,
                                                      progressColor: Colors.red,
                                                      arcBackgroundColor:
                                                          Colors.grey.shade200,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    4.0,
                                                  ),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {});
                                                    },
                                                    child: CircularPercentIndicator(
                                                      arcType: ArcType.HALF,
                                                      radius: 55.0,
                                                      lineWidth: 20.0,
                                                      animation: true,
                                                      percent:
                                                          CurrentQtrPercentage /
                                                          100,
                                                      center: Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 30,
                                                          ),
                                                          Text(
                                                            CurrentQtrPercentageStr,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  touchedQuarterGoals
                                                                  ? 13.0
                                                                  : 12.0,
                                                              color:
                                                                  touchedQuarterGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          Text(
                                                            CurrentQtrSalesStr,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  touchedQuarterGoals
                                                                  ? 11.0
                                                                  : 10.0,
                                                              color:
                                                                  touchedQuarterGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            "Q$currentQuarter Sales \n($CurrentQtrTargetStr)",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  touchedQuarterGoals
                                                                  ? 11.0
                                                                  : 10.0,
                                                              color:
                                                                  touchedQuarterGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      curve: Curves.linear,
                                                      circularStrokeCap:
                                                          CircularStrokeCap
                                                              .butt,
                                                      progressColor:
                                                          Colors.orange,
                                                      arcBackgroundColor:
                                                          Colors.grey.shade200,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    4.0,
                                                  ),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {});
                                                    },
                                                    child: CircularPercentIndicator(
                                                      arcType: ArcType.HALF,
                                                      radius: 55.0,
                                                      lineWidth: 20.0,
                                                      animation: true,
                                                      percent:
                                                          YtdPercentage / 100,
                                                      center: Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 30,
                                                          ),
                                                          Text(
                                                            YtdPercentageStr,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  touchedYTDGoals
                                                                  ? 13.0
                                                                  : 12.0,
                                                              color:
                                                                  touchedYTDGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          Text(
                                                            YtdSalesStr,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  touchedYTDGoals
                                                                  ? 11.0
                                                                  : 10.0,
                                                              color:
                                                                  touchedYTDGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            "YTD \n($YtdTargetStr)",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  touchedYTDGoals
                                                                  ? 11.0
                                                                  : 10.0,
                                                              color:
                                                                  touchedYTDGoals
                                                                  ? Colors.cyan
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      curve: Curves.linear,
                                                      circularStrokeCap:
                                                          CircularStrokeCap
                                                              .butt,
                                                      progressColor:
                                                          Colors.green,
                                                      arcBackgroundColor:
                                                          Colors.grey.shade200,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        RepaintBoundary(
                          child: Row(
                            children: [
                              Expanded(
                                child: buildQuarterCard(
                                  quarter: "Q1",
                                  percentage: Q1PercentageStr,
                                  color: const Color(0xFF6CCC3F),
                                  target: Q1TargetStr,
                                  achieved: Q1SalesStr,
                                  difference: Q1DiffStr,
                                  average: Q1AverageStr,
                                ),
                              ),

                              const SizedBox(width: 6),

                              Expanded(
                                child: buildQuarterCard(
                                  quarter: "Q2",
                                  percentage: Q2PercentageStr,
                                  color: const Color(0xFFF49136),
                                  target: Q2TargetStr,
                                  achieved: Q2SalesStr,
                                  difference: Q2DiffStr,
                                  average: Q2AverageStr,
                                ),
                              ),

                              const SizedBox(width: 6),

                              Expanded(
                                child: buildQuarterCard(
                                  quarter: "Q3",
                                  percentage: Q3PercentageStr,
                                  color: const Color(0xFFE92729),
                                  target: Q3TargetStr,
                                  achieved: Q3SalesStr,
                                  difference: Q3DiffStr,
                                  average: Q3AverageStr,
                                ),
                              ),

                              const SizedBox(width: 6),

                              Expanded(
                                child: buildQuarterCard(
                                  quarter: "Q4",
                                  percentage: Q4PercentageStr,
                                  color: const Color(0xFF6CCC3F),
                                  target: Q4TargetStr,
                                  achieved: Q4SalesStr,
                                  difference: Q4DiffStr,
                                  average: Q4AverageStr,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Monthwise Sales Analysis',
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
                        const Text('Achieved', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 10),

                        Container(
                          height: 8,
                          width: 8,
                          color: Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text('Target', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () async {
                          await generateSalesExcel(monthlySalesList);
                        },
                        child: const Text('Download Excel'),
                      ),

                      PopupMenuItem(
                        onTap: () async {
                          await generateSalesPDF(monthlySalesList);
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _buildMonthlySalesChart(),
                  ),
                ),

                Visibility(
                  visible: rsmwiseSalesList.rsmwiseData.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DashboardCardUI(
                      title: 'Regional Manager Analysis',
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
                            'Achieved',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 8,
                            width: 8,
                            color: Color(0xFFFF9F47),
                          ),
                          const SizedBox(width: 5),
                          const Text('Target', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      menuItems: [
                        PopupMenuItem(
                          onTap: () async {
                            await generateRsmSalesExcel(rsmwiseSalesList);
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            await generateRsmSalesPDF(rsmwiseSalesList);
                          },
                          child: const Text("Download PDF"),
                        ),
                      ],
                      child: _regionalManagerAnalysis(),
                    ),
                  ),
                ),

                Visibility(
                  visible: asmwiseSalesList.asmwiseData.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DashboardCardUI(
                      title: 'Sales Manager\nAnalysis',
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
                            'Achieved',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 8,
                            width: 8,
                            color: Color(0xFFFF9F47),
                          ),
                          const SizedBox(width: 5),
                          const Text('Target', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      menuItems: [
                        PopupMenuItem(
                          onTap: () async {
                            await generateAsmSalesExcel(asmwiseSalesList);
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            await generateAsmSalesPDF(asmwiseSalesList);
                          },
                          child: const Text("Download PDF"),
                        ),
                      ],
                      child: _salesManagerAnalysis(),
                    ),
                  ),
                ),

                Visibility(
                  visible: tsmwiseSalesList.tsmwiseData.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DashboardCardUI(
                      title: 'Sales Person\nAnalysis',
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
                            'Achieved',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 8,
                            width: 8,
                            color: Color(0xFFFF9F47),
                          ),
                          const SizedBox(width: 5),
                          const Text('Target', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      menuItems: [
                        PopupMenuItem(
                          onTap: () async {
                            await generateTsmSalesExcel(tsmwiseSalesList);
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            await generateTsmSalesPDF(tsmwiseSalesList);
                          },
                          child: const Text("Download PDF"),
                        ),
                      ],
                      child: _salesPersonAnalysis(),
                    ),
                  ),
                ),

                Visibility(
                  visible:
                      customerStateWiseSalesList.customerStateData.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DashboardCardUI(
                      title: 'Customer State Wise\nAnalysis',
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
                            'Achieved',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 8,
                            width: 8,
                            color: Color(0xFFFF9F47),
                          ),
                          const SizedBox(width: 5),
                          const Text('Target', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      menuItems: [
                        PopupMenuItem(
                          onTap: () async {
                            await generateCustomerStateSalesExcel(
                              customerStateWiseSalesList,
                            );
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            await generateCustomerStateSalesPDF(
                              customerStateWiseSalesList,
                            );
                          },
                          child: const Text("Download PDF"),
                        ),
                      ],
                      child: _buildCustomerStateWiseSalesChart(),
                    ),
                  ),
                ),

                Visibility(
                  visible: customerWiseSalesList.customerData.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DashboardCardUI(
                      title: 'Customer Analysis',
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
                            'Achieved',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 8,
                            width: 8,
                            color: Color(0xFFFF9F47),
                          ),
                          const SizedBox(width: 5),
                          const Text('Target', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      menuItems: [
                        PopupMenuItem(
                          onTap: () async {
                            generateCustomerSalesExcel(customerWiseSalesList);
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            generateCustomerSalesPDF(customerWiseSalesList);
                          },
                          child: const Text("Download PDF"),
                        ),
                      ],
                      child: _buildCustomerSalesChart(),
                    ),
                  ),
                ),

                Visibility(
                  visible:
                      productGroupwiseSalesList.productGroupData.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DashboardCardUI(
                      title: 'Item Groupwise\nAnalysis',
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
                            'Achieved',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 8,
                            width: 8,
                            color: Color(0xFFFF9F47),
                          ),
                          const SizedBox(width: 5),
                          const Text('Target', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      menuItems: [
                        PopupMenuItem(
                          onTap: () async {
                            generateItemGroupSalesExcel();
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            generateItemGroupSalesPDF();
                          },
                          child: const Text('Download PDF'),
                        ),
                      ],
                      child: _itemGroupWiseAnalysis(),
                    ),
                  ),
                ),

                Visibility(
                  visible: productwiseSalesList.productData.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DashboardCardUI(
                      title: 'Item Analysis',
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
                            'Achieved',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 8,
                            width: 8,
                            color: Color(0xFFFF9F47),
                          ),
                          const SizedBox(width: 5),
                          const Text('Target', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      menuItems: [
                        PopupMenuItem(
                          onTap: () async {
                            generateItemSalesExcel(productwiseSalesList);
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            generateItemSalesPDF(productwiseSalesList);
                          },
                          child: const Text('Download PDF'),
                        ),
                      ],
                      child: _itemWiseAnalysis(),
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
          removeFilter();
        });
      }
    });
  }

  int determineGrpIndex(
    Offset tapPosition,
    List<AsmwiseData> asmwiseData,
    double chartWidth,
  ) {
    double barWidth = chartWidth / asmwiseData.length;
    int index = (tapPosition.dx / barWidth).floor();
    if (index >= 0 && index < asmwiseData.length) {
      return index;
      // return asmwiseData.length > 1 ? index - 1 : index;
    } else {
      return -1; // Indicating that no bar was tapped
    }
  }

  void _scrollDown() {
    salesPerformancePageController.animateTo(
      800, //salesPerformancePageController.position.maxScrollExtent
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  Widget buildQuarterCard({
    required String quarter,
    required String percentage,
    required Color color,
    required String target,
    required String achieved,
    required String difference,
    required String average,
  }) {
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      richMessage: WidgetSpan(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$quarter Analysis",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Target : $target"),
            Text("Achieved : $achieved"),
            Text("Difference : $difference"),
            Text("Monthly Avg : $average"),
          ],
        ),
      ),
      child: Container(
        // width: 110,
        height: 130,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                quarter,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              percentage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(
              achieved,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            SizedBox(
              height: 20,
              child: CustomPaint(
                painter: SparklinePainter(color),
                size: const Size(double.infinity, 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySalesChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    double barChartWidth = 0.0;
    monthlySalesList.monthlyData.length > 6
        ? barChartWidth = screenWidth * 1.4
        : barChartWidth = screenWidth;
    return FinanceHorizontalChartScroll(
      controller: _monthlySalesHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: barChartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(monthlySalesList),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                bottomTitles: AxisTitles(
                  sideTitles: _bottomTitles2,
                  axisNameSize: 14,
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
              barGroups: _monthlySalesAnalysisChart(
                monthlySalesList.monthlyData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (flTouchEvent is! FlTapUpEvent ||
                      barTouchResponse == null ||
                      barTouchResponse.spot == null) {
                    return;
                  }

                  final index = barTouchResponse.spot!.spot.x.toInt();
                  if (index < 0 ||
                      index >= monthlySalesList.monthlyData.length) {
                    return;
                  }

                  final isDeselecting = selectedMonthIndex == index;

                  setState(() {
                    selectedMonthIndex = isDeselecting ? -1 : index;
                    touchedMonth =
                        monthlySalesList.monthlyData[index].monthName;
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

                    touchedMonthIndex = (touchedMonthIndex == 0
                        ? months.indexOf(touchedMonth.substring(0, 3)) + 1
                        : 0);
                    selectedChart = index.toDouble();
                    showDrillDownChart = true;
                    loadDataWithFilter(
                      touchedMonthIndex,
                      touchedRegionalManager,
                      touchedSalesManager,
                      touchedSalesRep,
                      touchedState,
                      touchedCustomer,
                      touchedProductGroup,
                      touchedProduct,
                    );
                    touchedYearGraph = true;
                  });
                  if (showProductSaleChart != true) {
                    await Future.delayed(const Duration(milliseconds: 50));
                    _scrollDown();
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
                      '${monthlySalesList.monthlyData[grpIndex].monthName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Achievement : ${(rodData.toY / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Target : ${(rodData.backDrawRodData.toY / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${((rodData.toY / 100000) - (rodData.backDrawRodData.toY / 100000)).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${(((rodData.toY / 100000) / (rodData.backDrawRodData.toY / 100000)) * 100).toStringAsFixed(2)}%",
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

  Widget _regionalManagerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    int len = rsmwiseSalesList.rsmwiseData.length;
    double chartWidth = len > 5 ? screenWidth + (70 * len) + 100 : screenWidth;
    return FinanceHorizontalChartScroll(
      controller: _regionalManagerHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              /// SAFE MAX Y
              maxY: max(1, getRsmMaxValue(rsmwiseSalesList)),
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
                  sideTitles: _bottomTitlesRsm,
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

              barGroups: _regionalManagerAnalysisChart(
                rsmwiseSalesList.rsmwiseData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                handleBuiltInTouches: true,
                touchExtraThreshold: const EdgeInsets.all(10),
                touchCallback: (event, response) async {
                  if (response == null || response.spot == null) return;
                  int index = response.spot!.spot.x.toInt();

                  /// SAFETY CHECK
                  if (index < 0 ||
                      index >= rsmwiseSalesList.rsmwiseData.length) {
                    return;
                  }

                  /// LONG PRESS → TOOLTIP
                  if (event is FlLongPressStart) {
                    setState(() {
                      tooltipIndex = index;
                      showTooltip = true;
                    });
                    return;
                  }

                  /// LONG PRESS END
                  if (event is FlLongPressEnd) {
                    setState(() {
                      showTooltip = false;
                    });
                    return;
                  }

                  /// TAP → DRILLDOWN
                  if (event is FlTapUpEvent) {
                    setState(() {
                      showTooltip = false;
                      touchedRegionalManager = touchedRegionalManager == ""
                          ? rsmwiseSalesList.rsmwiseData[index].rsmName
                          : "";
                      selectedChart = index.toDouble();
                      showDrillDownChart = true;
                      touchedYearGraph = true;
                    });

                    loadDataWithFilter(
                      touchedMonthIndex,
                      touchedRegionalManager,
                      touchedSalesManager,
                      touchedSalesRep,
                      touchedState,
                      touchedCustomer,
                      touchedProductGroup,
                      touchedProduct,
                    );

                    if (!showProductSaleChart) {
                      await Future.delayed(const Duration(milliseconds: 50));
                      _scrollDown();
                    }
                  }
                },

                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,

                  fitInsideVertically: true,

                  getTooltipColor: (group) => Colors.white,

                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (!showTooltip || tooltipIndex != groupIndex) {
                      return null;
                    }

                    final data = rsmwiseSalesList.rsmwiseData[groupIndex];

                    final salesL = data.salesAmount / 100000;

                    final targetL = data.targetAmount / 100000;

                    final diffL = salesL - targetL;

                    final percent = data.targetAmount == 0
                        ? "0%"
                        : "${((data.salesAmount / data.targetAmount) * 100).toStringAsFixed(0)}%";

                    return BarTooltipItem(
                      '${data.rsmName}\n',

                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),

                      children: [
                        TextSpan(
                          text:
                              "Achievement : ${salesL.toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        TextSpan(
                          text: "Target : ${targetL.toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        TextSpan(
                          text: "Difference : ${diffL.toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        TextSpan(
                          text: "Percentage : $percent",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _salesManagerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    int len = asmwiseSalesList.asmwiseData.length;
    double chartWidth = len > 5
        ? screenWidth + (70.0 * len) + 100
        : screenWidth;

    return FinanceHorizontalChartScroll(
      controller: _salesManagerHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              /// SAFE MAX Y
              maxY: max(1, getAsmMaxValue(asmwiseSalesList)),
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
                  sideTitles: _bottomTitlesAsm,
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

              barGroups: _salesManagerAnalysisChart(
                asmwiseSalesList.asmwiseData,
              ),

              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                handleBuiltInTouches: true,
                touchExtraThreshold: const EdgeInsets.all(10),

                touchCallback: (event, response) async {
                  if (response == null || response.spot == null) return;

                  int index = response.spot!.spot.x.toInt();

                  /// SAFETY CHECK
                  if (index < 0 ||
                      index >= asmwiseSalesList.asmwiseData.length) {
                    return;
                  }

                  /// LONG PRESS → TOOLTIP
                  if (event is FlLongPressStart) {
                    setState(() {
                      tooltipIndex = index;

                      showTooltip = true;
                    });

                    return;
                  }

                  /// LONG PRESS END
                  if (event is FlLongPressEnd) {
                    setState(() {
                      showTooltip = false;
                    });

                    return;
                  }

                  /// TAP → DRILLDOWN
                  if (event is FlTapUpEvent) {
                    setState(() {
                      showTooltip = false;
                      touchedSalesManager = touchedSalesManager == ""
                          ? asmwiseSalesList.asmwiseData[index].asmName
                          : "";
                      selectedChart = index.toDouble();
                      showDrillDownChart = true;
                      touchedYearGraph = true;
                    });

                    loadDataWithFilter(
                      touchedMonthIndex,
                      touchedRegionalManager,
                      touchedSalesManager,
                      touchedSalesRep,
                      touchedState,
                      touchedCustomer,
                      touchedProductGroup,
                      touchedProduct,
                    );

                    if (!showProductSaleChart) {
                      await Future.delayed(const Duration(milliseconds: 50));

                      _scrollDown();
                    }
                  }
                },

                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (group) => Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (!showTooltip || tooltipIndex != groupIndex) {
                      return null;
                    }
                    final data = asmwiseSalesList.asmwiseData[groupIndex];
                    final salesL = data.salesAmount / 100000;
                    final targetL = data.targetAmount / 100000;
                    final diffL = salesL - targetL;
                    final percent = data.targetAmount == 0
                        ? "0%"
                        : "${((data.salesAmount / data.targetAmount) * 100).toStringAsFixed(0)}%";

                    return BarTooltipItem(
                      '${data.asmName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),

                      children: [
                        TextSpan(
                          text:
                              "Achievement : ${salesL.toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        TextSpan(
                          text: "Target : ${targetL.toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        TextSpan(
                          text: "Difference : ${diffL.toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        TextSpan(
                          text: "Percentage : $percent",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _salesPersonAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = tsmwiseSalesList.tsmwiseData.length;
    if (tsmwiseSalesList.tsmwiseData.length > 5) {
      chartWidth = screenWidth + (70 * len) + 100;
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _salesPersonHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: max(1, getTsmMaxValue(tsmwiseSalesList)),
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
                  sideTitles: _bottomTitlesTsm,
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
              barGroups: _salesPersonAnalysisChart(
                tsmwiseSalesList.tsmwiseData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                handleBuiltInTouches: true,
                touchExtraThreshold: const EdgeInsets.all(10),
                touchCallback: (event, response) async {
                  if (response == null || response.spot == null) return;
                  int index = response.spot!.spot.x.toInt();
                  if (index < 0 ||
                      index >= tsmwiseSalesList.tsmwiseData.length) {
                    return;
                  }

                  /// LONG PRESS → Tooltip
                  if (event is FlLongPressStart) {
                    setState(() {
                      tooltipIndex = index;
                      showTooltip = true;
                    });
                    return;
                  }

                  /// LONG PRESS END → Hide tooltip
                  if (event is FlLongPressEnd) {
                    setState(() {
                      showTooltip = false;
                    });
                    return;
                  }

                  /// TAP → Drilldown
                  if (event is FlTapUpEvent) {
                    setState(() {
                      showTooltip = false;
                      touchedSalesRep = touchedSalesRep == ""
                          ? tsmwiseSalesList.tsmwiseData[index].tsmName
                          : "";
                      selectedChart = index.toDouble();
                      showDrillDownChart = true;
                      touchedYearGraph = true;
                    });

                    loadDataWithFilter(
                      touchedMonthIndex,
                      touchedRegionalManager,
                      touchedSalesManager,
                      touchedSalesRep,
                      touchedState,
                      touchedCustomer,
                      touchedProductGroup,
                      touchedProduct,
                    );
                    if (showProductSaleChart != true) {
                      await Future.delayed(const Duration(milliseconds: 50));
                      _scrollDown();
                    }
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (group) => Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (!showTooltip || tooltipIndex != groupIndex) {
                      return null;
                    }
                    return BarTooltipItem(
                      '${tsmwiseSalesList.tsmwiseData[groupIndex].tsmName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text:
                              "Achievement : ${(tsmwiseSalesList.tsmwiseData[groupIndex].salesAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Target : ${(tsmwiseSalesList.tsmwiseData[groupIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${((tsmwiseSalesList.tsmwiseData[groupIndex].salesAmount - tsmwiseSalesList.tsmwiseData[groupIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${tsmwiseSalesList.tsmwiseData[groupIndex].targetAmount == 0 ? "0%" : "${((tsmwiseSalesList.tsmwiseData[groupIndex].salesAmount / tsmwiseSalesList.tsmwiseData[groupIndex].targetAmount) * 100).toStringAsFixed(0)}%"}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerStateWiseSalesChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = customerStateWiseSalesList.customerStateData.length;
    if (customerStateWiseSalesList.customerStateData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _customerStateWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getCustomerStateMaxValue(customerStateWiseSalesList),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedState = touchedState == ""
                            ? customerStateWiseSalesList
                                  .customerStateData[barTouchResponse
                                      .spot!
                                      .spot
                                      .x
                                      .toInt()]
                                  .stateName
                            : "";
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showDrillDownChart = true;
                        loadDataWithFilter(
                          touchedMonthIndex,
                          touchedRegionalManager,
                          touchedSalesManager,
                          touchedSalesRep,
                          touchedState,
                          touchedCustomer,
                          touchedProductGroup,
                          touchedProduct,
                        );
                        touchedYearGraph = true;
                      }
                    });
                    if (showProductSaleChart != true) {
                      await Future.delayed(const Duration(milliseconds: 50));
                      _scrollDown();
                    }
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  maxContentWidth: 200,
                  tooltipBorder: const BorderSide(
                    width: 4.0,
                    color: Colors.black12,
                    style: BorderStyle.none,
                  ),
                  getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                    return BarTooltipItem(
                      '${customerStateWiseSalesList.customerStateData[grpIndex].stateName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Achievement : ${(customerStateWiseSalesList.customerStateData[grpIndex].saleAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "3 Month Avg. : ${(customerStateWiseSalesList.customerStateData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${((customerStateWiseSalesList.customerStateData[grpIndex].saleAmount - customerStateWiseSalesList.customerStateData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${((customerStateWiseSalesList.customerStateData[grpIndex].saleAmount / customerStateWiseSalesList.customerStateData[grpIndex].targetAmount) * 100).ceil().toStringAsFixed(0)}%",
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
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                bottomTitles: AxisTitles(
                  sideTitles: _bottomTitlesCustomerState,
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
              barGroups: _customerStateWiseAnalysisChart(
                customerStateWiseSalesList.customerStateData,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSalesChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    double barChartWidth = 0.0;
    int length = customerWiseSalesList.customerData.length;
    length > 6
        ? barChartWidth = screenWidth + (30 * length)
        : barChartWidth = screenWidth;

    final amounts = customerWiseSalesList.customerData
        .expand((e) => [e.saleAmount, e.targetAmount])
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
      chartMaxY = _roundedPositiveMaxY([maxPositive]);
      chartMinY = _roundedNegativeMinY([maxNegative]);
    } else if (hasPositive) {
      double maxPositive = amounts.reduce((a, b) => a > b ? a : b);
      chartMaxY = _roundedPositiveMaxY([maxPositive]);
      chartMinY = 0;
    } else if (hasNegative) {
      double maxNegative = amounts.reduce((a, b) => a < b ? a : b);
      chartMaxY = 0;
      chartMinY = _roundedNegativeMinY([maxNegative]);
    }

    return FinanceHorizontalChartScroll(
      controller: _customerSalesHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: barChartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              minY: chartMinY,
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedCustomer = touchedCustomer == ""
                            ? customerWiseSalesList
                                  .customerData[barTouchResponse.spot!.spot.x
                                      .toInt()]
                                  .customerCode
                            : "";
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showDrillDownChart = true;
                        loadDataWithFilter(
                          touchedMonthIndex,
                          touchedRegionalManager,
                          touchedSalesManager,
                          touchedSalesRep,
                          touchedState,
                          touchedCustomer,
                          touchedProductGroup,
                          touchedProduct,
                        );
                        touchedYearGraph = true;
                      }
                    });
                    if (showProductSaleChart != true) {
                      await Future.delayed(const Duration(milliseconds: 50));
                      _scrollDown();
                    }
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  maxContentWidth: 200,
                  tooltipBorder: const BorderSide(
                    width: 4.0,
                    color: Colors.black12,
                    style: BorderStyle.none,
                  ),
                  getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                    return BarTooltipItem(
                      '${customerWiseSalesList.customerData[grpIndex].customerName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Achievement : ${(customerWiseSalesList.customerData[grpIndex].saleAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "3 Month Avg. : ${(customerWiseSalesList.customerData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${customerWiseSalesList.customerData[grpIndex].targetAmount == 0 ? 0 : ((customerWiseSalesList.customerData[grpIndex].saleAmount - customerWiseSalesList.customerData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${customerWiseSalesList.customerData[grpIndex].targetAmount == 0 ? 0 : ((customerWiseSalesList.customerData[grpIndex].saleAmount / customerWiseSalesList.customerData[grpIndex].targetAmount) * 100).ceil().toStringAsFixed(0)}%",
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
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                bottomTitles: AxisTitles(
                  sideTitles: _bottomTitlesCustomer,
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
              barGroups: _customerWiseAnalysisChart(
                customerWiseSalesList.customerData,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemGroupWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = productGroupwiseSalesList.productGroupData.length;
    if (productGroupwiseSalesList.productGroupData.length > 5) {
      chartWidth = screenWidth + (30 * len);
    } else {
      chartWidth = screenWidth;
    }
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
              maxY: getItemGroupMaxValue(productGroupwiseSalesList),
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
                  sideTitles: _bottomTitlesProductGroup,
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
              barGroups: _productsGroupWiseAnalysisChart(
                productGroupwiseSalesList.productGroupData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedProductGroup = touchedProductGroup == ""
                            ? productGroupwiseSalesList
                                  .productGroupData[barTouchResponse
                                      .spot!
                                      .spot
                                      .x
                                      .toInt()]
                                  .productGroupName
                            : "";
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showDrillDownChart = true;
                        loadDataWithFilter(
                          touchedMonthIndex,
                          touchedRegionalManager,
                          touchedSalesManager,
                          touchedSalesRep,
                          touchedState,
                          touchedCustomer,
                          touchedProductGroup,
                          touchedProduct,
                        );
                        touchedYearGraph = true;
                      }
                    });
                    if (showProductSaleChart != true) {
                      await Future.delayed(const Duration(milliseconds: 50));
                      _scrollDown();
                    }
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  maxContentWidth: 200,
                  tooltipBorder: const BorderSide(
                    width: 4.0,
                    color: Colors.black12,
                    style: BorderStyle.none,
                  ),
                  getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                    return BarTooltipItem(
                      '${productGroupwiseSalesList.productGroupData[grpIndex].productGroupName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Achievement : ${(productGroupwiseSalesList.productGroupData[grpIndex].salesAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "3 Month Avg. : ${(productGroupwiseSalesList.productGroupData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${((productGroupwiseSalesList.productGroupData[grpIndex].salesAmount - productGroupwiseSalesList.productGroupData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${((productGroupwiseSalesList.productGroupData[grpIndex].salesAmount / productGroupwiseSalesList.productGroupData[grpIndex].targetAmount) * 100).ceil().toStringAsFixed(0)}%",
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

  Widget _itemWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double barChartWidth = 0.0;
    int length = productwiseSalesList.productData.length;
    length > 6
        ? barChartWidth = screenWidth + (35 * length)
        : barChartWidth = screenWidth;

    final amounts = productwiseSalesList.productData
        .expand((e) => [e.salesAmount, e.targetAmount])
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
      chartMaxY = _roundedPositiveMaxY([maxPositive]);
      chartMinY = _roundedNegativeMinY([maxNegative]);
    } else if (hasPositive) {
      double maxPositive = amounts.reduce((a, b) => a > b ? a : b);
      chartMaxY = _roundedPositiveMaxY([maxPositive]);
      chartMinY = 0;
    } else if (hasNegative) {
      double maxNegative = amounts.reduce((a, b) => a < b ? a : b);
      chartMaxY = 0;
      chartMinY = _roundedNegativeMinY([maxNegative]);
    }

    return FinanceHorizontalChartScroll(
      controller: _itemWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: barChartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              minY: chartMinY,
              barTouchData: BarTouchData(
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      setState(() {
                        touchedProduct = touchedProduct == ""
                            ? productwiseSalesList
                                  .productData[barTouchResponse.spot!.spot.x
                                      .toInt()]
                                  .productCode
                            : "";
                        loadDataWithFilter(
                          touchedMonthIndex,
                          touchedRegionalManager,
                          touchedSalesManager,
                          touchedSalesRep,
                          touchedState,
                          touchedCustomer,
                          touchedProductGroup,
                          touchedProduct,
                        );
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showProductSaleChart = true;
                        touchedYearGraph = true;
                      });
                    }
                  }
                },
                allowTouchBarBackDraw: true,
                touchTooltipData: BarTouchTooltipData(
                  maxContentWidth: 200,
                  tooltipBorder: const BorderSide(
                    width: 4.0,
                    color: Colors.black12,
                    style: BorderStyle.none,
                  ),
                  getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                    return BarTooltipItem(
                      '${productwiseSalesList.productData[grpIndex].productName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Achievement : ${(productwiseSalesList.productData[grpIndex].salesAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "3 Month Avg. : ${(productwiseSalesList.productData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${((productwiseSalesList.productData[grpIndex].salesAmount - productwiseSalesList.productData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${((productwiseSalesList.productData[grpIndex].salesAmount / productwiseSalesList.productData[grpIndex].targetAmount) * 100).ceil().toStringAsFixed(0)}%",
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
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                bottomTitles: AxisTitles(
                  sideTitles: _bottomTitlesProduct,
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
              barGroups: _productsWiseAnalysisChart(
                productwiseSalesList.productData,
              ),
            ),
          ),
        ),
      ),
    );
  }

  showLoaderDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          Container(
            margin: const EdgeInsets.only(left: 7),
            child: const Text("Loading..."),
          ),
        ],
      ),
    );
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
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
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options - Sales',
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
                  Expanded(
                    child: Row(
                      children: [
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
                                        categories.length - 1
                                    ? Column(
                                        children: [
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
                                                (selectedCategoryIndex <
                                                        savedFinanceReceivablesOptions
                                                            .length &&
                                                    index <
                                                        savedFinanceReceivablesOptions[selectedCategoryIndex]
                                                            .length)
                                                ? savedFinanceReceivablesOptions[selectedCategoryIndex][index]
                                                : false,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value == true) {
                                                  selectedFinanceReceivablesOptions[selectedCategoryIndex][index] =
                                                      true;
                                                } else {
                                                  selectedFinanceReceivablesOptions[selectedCategoryIndex][index] =
                                                      false;
                                                }
                                                savedFinanceReceivablesOptionsTemp =
                                                    savedFinanceReceivablesOptions;
                                                if (savedFinanceReceivablesOptions
                                                    .isEmpty) {
                                                  savedFinanceReceivablesOptionsTemp =
                                                      savedFinanceReceivablesOptions;
                                                }
                                                savedFinanceReceivablesOptions =
                                                    selectedFinanceReceivablesOptions;
                                              });
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

                                      fromFilter = false;

                                      savedFinanceReceivablesOptionsTemp =
                                          savedFinanceReceivablesOptions;

                                      // toggleCheckbox();
                                      loadDataFuture = filterFunction();

                                      setState(() {
                                        resetFinanceReceivablesOptions();
                                      });
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
                                      Navigator.pop(context);
                                      setState(() {
                                        chartDataLoaded = false;
                                      });
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        fromDateFilter = null;
                                        toDateFilter = null;
                                        dateFilterFlag = false;
                                        chartDataLoaded = false;
                                        chartDataLoaded = false;
                                        setState(() {
                                          chartDataLoaded = false;
                                        });
                                        loadDataFuture = removeFilter();
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

  Widget _buildLazyLoadIndicator() {
    if (!isLazyLoading && animatedProgress == 0.0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: 220, // FIXED, CLEAN, DASHBOARD-SAFE
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: animatedProgress),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 6, // thinner looks better
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isLazyLoading
                ? "Loaded ${loadedBatchCount * 5000} records…"
                : "All data loaded",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget buildQuarterAnalysisRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// Quarter boxes take remaining width
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  const SizedBox(width: 6),

                  quarterBox(
                    "Q1",
                    Q1PercentageStr,
                    const Color(0xff6CCC3F),
                    "Quarter 1 Analysis",
                    Q1TargetStr,
                    Q1SalesStr,
                    Q1DiffStr,
                    Q1PercentageStr,
                    Q1AverageStr,
                  ),

                  quarterBox(
                    "Q2",
                    Q2PercentageStr,
                    const Color(0xFFF49136),
                    "Quarter 2 Analysis",
                    Q2TargetStr,
                    Q2SalesStr,
                    Q2DiffStr,
                    Q2PercentageStr,
                    Q2AverageStr,
                  ),

                  quarterBox(
                    "Q3",
                    Q3PercentageStr,
                    const Color(0xFFE92729),
                    "Quarter 3 Analysis",
                    Q3TargetStr,
                    Q3SalesStr,
                    Q3DiffStr,
                    Q3PercentageStr,
                    Q3AverageStr,
                  ),

                  quarterBox(
                    "Q4",
                    Q4PercentageStr,
                    const Color(0xff6CCC3F),
                    "Quarter 4 Analysis",
                    Q4TargetStr,
                    Q4SalesStr,
                    Q4DiffStr,
                    Q4PercentageStr,
                    Q4AverageStr,
                  ),
                ],
              ),
            ),
          ),
        ),

        /// Menu keeps natural width
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () {
                generateSalesAnalysisQuarterDataYTDExcel();
              },
              child: const Text("Download Excel"),
            ),
          ],
        ),
      ],
    );
  }

  Widget quarterBox(
    String quarter,
    String percentage,
    Color color,
    String title,
    String target,
    String achieved,
    String diff,
    String percent,
    String avg,
  ) {
    return Tooltip(
      triggerMode: TooltipTriggerMode.longPress,
      preferBelow: false,
      richMessage: WidgetSpan(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

            Text("Target : ${target.isEmpty ? "-" : target}"),
            Text("Achieved : ${achieved.isEmpty ? "-" : achieved}"),
            Text("Difference : ${diff.isEmpty ? "-" : diff}"),
            Text("Percentage : ${percent.isEmpty ? "-" : percent}"),
            Text("Monthly Avg. : ${avg.isEmpty ? "-" : avg}"),
          ],
        ),
      ),

      child: Row(
        children: [
          /// Q BOX
          Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.5),
              border: const Border(
                left: BorderSide(color: Colors.black),
                top: BorderSide(color: Colors.black),
                bottom: BorderSide(color: Colors.black),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              quarter,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          /// % BOX
          Container(
            height: 38,
            alignment: Alignment.center,
            // constraints: const BoxConstraints(minWidth: 45),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.black),
                top: BorderSide(color: Colors.black),
                bottom: BorderSide(color: Colors.black),
                right: quarter == "Q4"
                    ? BorderSide(color: Colors.black)
                    : BorderSide.none,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(percentage.isEmpty ? "-" : percentage),
          ),
        ],
      ),
    );
  }
}

class MyTreeTile extends StatelessWidget {
  const MyTreeTile({super.key, required this.entry, required this.onTap});

  final TreeEntry<MyNode> entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: TreeIndentation(
        entry: entry,
        guide: const IndentGuide.connectingLines(indent: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
          child: Row(
            children: [
              FolderButton(
                icon: const Icon(Icons.person_2_sharp),
                closedIcon: const Icon(Icons.person_2_sharp),
                openedIcon: const Icon(Icons.person_2_outlined),
                isOpen: entry.hasChildren ? entry.isExpanded : null,
                onPressed: entry.hasChildren ? onTap : null,
              ),
              Text(entry.node.title),
            ],
          ),
        ),
      ),
    );
  }
}

class MyNode {
  MyNode({
    required this.title,
    required this.id,
    this.children = const <MyNode>[],
  });

  final String title;
  final int id;
  List<MyNode> children;
}
