// ignore_for_file: file_names, use_build_context_synchronously, non_constant_identifier_names, avoid_web_libraries_in_flutter, strict_top_level_inference

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import '../../../api_helper.dart';
import '../../../classes/dashBoard.dart';
import '../../../classes/dataManager.dart';
import '../../../login_screen.dart';
import '../../../notificationService.dart';
import '../ReportService.dart';
import '../dashboard_card_ui.dart';

List<List<String>> filterOptions = [
  listOfRSM,
  listOfASM,
  listOfTSM,
  listOfString,
  [],
];
Map<String, DateTime> _dateCache = {};
List<String> listOfRSM = [];
List<String> listOfASM = [];
List<String> listOfTSM = [];
List<String> listOfString = [];

DateTime getParsedDate(String dateStr) {
  if (_dateCache.containsKey(dateStr)) {
    return _dateCache[dateStr]!;
  }
  final parsed = DateFormat('dd/MM/yyyy').parse(dateStr);
  _dateCache[dateStr] = parsed;
  return parsed;
}

class SalesOrderListSoAnalysisBIProvider with ChangeNotifier {
  List<SODetailsList> _soList = [];
  List<SODetailsList> get soList => _soList;
  void updateSalesOrder(List<SODetailsList> newSalesOrderList) {
    _soList = newSalesOrderList;
    notifyListeners();
  }
}

class SOAnalysisPage extends StatefulWidget {
  const SOAnalysisPage({super.key});

  @override
  State<SOAnalysisPage> createState() => _SOAnalysisPageState();
}

class _SOAnalysisPageState extends State<SOAnalysisPage> {
  final reportService = ReportService();

  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  bool showDrillDownChart = false;
  bool showProductSaleChart = false;
  bool showLastMonthBarChart = false;
  bool lastMonthChartFunc = false;
  bool lastThreeMonthChartFunc = false;
  int touchedMonthIndex = 0;
  String touchedRegionalManager = "";
  String touchedSalesManager = "";
  String touchedSalesRep = "";
  String touchedMonth = "";
  String touchedState = "";
  String touchedCustomer = "";
  String touchedProductGroup = "";
  String touchedProduct = "";
  String touchedAgingCategory = "";
  late Future<void> loadDataFuture;
  bool chartDataLoaded = false;
  double selectedChart = 0;
  List<Users> usersList = [];
  List<Users> childUsers = [];
  List<Users> usersListForFilter = [];
  List<Map<String, dynamic>> userList = [];
  String UserLevel = "0";

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

  String financialYear = "";
  String prevFinancialYear = "";
  double selectedProduct = 0;
  int currentQuarter = 0;

  bool YtdSOBarChartData = false;

  YTDSalesList ytdSalesList = YTDSalesList(ytdData: []);
  CustomerWiseSalesList customerAnalysisData = CustomerWiseSalesList(
    customerData: [],
  );
  AsmwiseSalesList salesManagerData = AsmwiseSalesList(asmwiseData: []);
  TsmwiseSalesList salesPersonData = TsmwiseSalesList(tsmwiseData: []);
  RsmwiseSalesList rsmwiseSalesList = RsmwiseSalesList(rsmwiseData: []);
  ProductGroupwiseSalesList itemGroupWiseData = ProductGroupwiseSalesList(
    productGroupData: [],
  );
  ProductwiseSalesList itemAnalysisData = ProductwiseSalesList(productData: []);
  OpenSOAgingList openSoAgingData = OpenSOAgingList(soAgingData: []);
  List<SODetailsList> SODetailList = [];
  MonthlySalesOrderList monthlySalesOrderList = MonthlySalesOrderList(
    soData: [],
  );

  final List<String> categories = ['RSM', 'ASM', 'TSM', 'Status', 'Date'];

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

  int? tooltipIndex;
  bool showTooltip = false;

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

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  SideTitles get _bottomTitlesRsm =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitlesRsm);

  Widget getBottomTitlesRsm(double val, TitleMeta meta) {
    String text = '';
    RsmwiseData rsmwiseData = rsmwiseSalesList.rsmwiseData.elementAt(
      val.toInt(),
    );
    text = rsmwiseData.rsmName;
    return Text(text.length > 5 ? text.substring(0, 5) : text);
  }

  SideTitles get _bottomTitlesCustomer => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      CustomerWiseData customerWiseData = customerAnalysisData.customerData
          .elementAt(value.toInt());
      text = customerWiseData.customerName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length < 5
              ? Text(text, style: const TextStyle(fontSize: 12))
              : Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                ),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesManager => SideTitles(
    showTitles: true,
    reservedSize: 35,
    getTitlesWidget: getBottomManagerTitles,
  );

  Widget getBottomManagerTitles(double val, TitleMeta meta) {
    String text = '';
    AsmwiseData asmData = salesManagerData.asmwiseData.elementAt(val.toInt());
    text = asmData.asmName;
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: RotationTransition(
        turns: const AlwaysStoppedAnimation(-25 / 360),
        child: Text(
          '${text.substring(0, 5)}...',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  SideTitles get _bottomTitlesSalesPerson => SideTitles(
    showTitles: true,
    reservedSize: 35,
    getTitlesWidget: getBottomSalesPersonTitles,
  );

  Widget getBottomSalesPersonTitles(double val, TitleMeta meta) {
    String text = '';
    TsmwiseData tsmData = salesPersonData.tsmwiseData.elementAt(val.toInt());
    text = tsmData.tsmName;
    return text.length > 5
        ? Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(-25 / 360),
              child: Text(
                '${text.substring(0, 5)}...',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(-25 / 360),
              child: Text(text, style: const TextStyle(fontSize: 12)),
            ),
          );
  }

  SideTitles get _bottomTitlesItemGroupWise => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      ProductGroupwiseData productwiseData = itemGroupWiseData.productGroupData
          .elementAt(value.toInt());
      text = productwiseData.productGroupName;
      return text.length > 5
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: RotationTransition(
                turns: const AlwaysStoppedAnimation(-25 / 360),
                child: Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: RotationTransition(
                turns: const AlwaysStoppedAnimation(-25 / 360),
                child: Text(text, style: const TextStyle(fontSize: 12)),
              ),
            );
    },
  );

  SideTitles get _bottomTitlesItem => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      ProductwiseData productwiseData = itemAnalysisData.productData.elementAt(
        value.toInt(),
      );
      text = productwiseData.productName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(
            '${text.substring(0, 5)}...',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesOpenSOAging => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      OpenSOAgingData soAgingData = openSoAgingData.soAgingData.elementAt(
        value.toInt(),
      );
      text = soAgingData.group;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 5
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  double getMaxValue(MonthlySalesOrderList monthlySalesOrderList) {
    double maxValue = 0.0;
    for (var soData in monthlySalesOrderList.soData) {
      maxValue = maxValue > soData.salesOrderAmount
          ? maxValue
          : soData.salesOrderAmount;
      maxValue = maxValue > soData.salesOrderTarget
          ? maxValue
          : soData.salesOrderTarget;
    }
    return ((maxValue ~/ 20000000) + 1) * 20000000;
  }

  double getCustomerMaxValue(CustomerWiseSalesList customerAnalysisData) {
    double maxValue = 0.0;
    for (var soData in customerAnalysisData.customerData) {
      maxValue = maxValue > soData.saleAmount ? maxValue : soData.saleAmount;
    }
    return ((maxValue ~/ 1000000) + 1) * 1000000;
  }

  double getRsmMaxValue(RsmwiseSalesList rsmManagerData) {
    double maxValue = 0.0;
    for (var soData in rsmManagerData.rsmwiseData) {
      maxValue = maxValue > soData.salesAmount ? maxValue : soData.salesAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    return ((maxValue ~/ 1000000) + 1) * 1000000;
  }

  double getAsmMaxValue(AsmwiseSalesList salesManagerData) {
    double maxValue = 0.0;
    for (var soData in salesManagerData.asmwiseData) {
      maxValue = maxValue > soData.salesAmount ? maxValue : soData.salesAmount;
    }
    return ((maxValue ~/ 100000) + 1) * 100000;
  }

  double getTsmMaxValue(TsmwiseSalesList salesPersonData) {
    double maxValue = 0.0;
    for (var soData in salesPersonData.tsmwiseData) {
      maxValue = maxValue > soData.salesAmount ? maxValue : soData.salesAmount;
    }
    return ((maxValue ~/ 2000000) + 1) * 2000000;
  }

  double getSoAgeingMaxValue(OpenSOAgingList openSoAgingData) {
    double maxValue = 0.0;
    for (var soData in openSoAgingData.soAgingData) {
      maxValue = maxValue > soData.receivableAmount
          ? maxValue
          : soData.receivableAmount;
    }
    return ((maxValue ~/ 20000000) + 1) * 20000000;
  }

  double getItemGroupMaxValue(ProductGroupwiseSalesList itemGroupWiseData) {
    double maxValue = 0.0;
    for (var soData in itemGroupWiseData.productGroupData) {
      maxValue = maxValue > soData.salesAmount ? maxValue : soData.salesAmount;
    }
    return ((maxValue ~/ 2000000) + 1) * 2000000;
  }

  double getItemMaxValue(ProductwiseSalesList itemAnalysisData) {
    double maxValue = 0.0;
    for (var soData in itemAnalysisData.productData) {
      maxValue = maxValue > soData.salesAmount ? maxValue : soData.salesAmount;
    }
    return ((maxValue ~/ 100000) + 1) * 100000;
  }

  List<BarChartGroupData> _monthWiseSOChartData(
    List<MonthlySalesOrderData> soData,
  ) {
    return soData
        .map(
          (so) => BarChartGroupData(
            x: soData.indexOf(so),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: so.salesOrderTarget,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF6CCC3F),
                borderRadius: BorderRadius.zero,
                toY: so.salesOrderAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _customerAnalysisChartData(
    List<CustomerWiseData> customerWiseSalesData,
  ) {
    return customerWiseSalesData
        .map(
          (sales) => BarChartGroupData(
            x: customerWiseSalesData.indexOf(sales),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: sales.targetAmount,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF6CCC3F),
                borderRadius: BorderRadius.zero,
                toY: sales.saleAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _regionalManagerAnalysisChart(
    List<RsmwiseData> rsmwiseData,
  ) {
    return rsmwiseData
        .map(
          (sales) => BarChartGroupData(
            x: rsmwiseData.indexOf(sales),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: sales.targetAmount,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF6CCC3F),
                borderRadius: BorderRadius.zero,
                toY: sales.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _salesManagerAnalysisChartData(
    List<AsmwiseData> monthlyData,
  ) {
    return monthlyData
        .map(
          (sales) => BarChartGroupData(
            x: monthlyData.indexOf(sales),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: sales.targetAmount,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF6CCC3F),
                borderRadius: BorderRadius.zero,
                toY: sales.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _salesPersonAnalysisChartData(
    List<TsmwiseData> monthlyData,
  ) {
    return monthlyData
        .map(
          (sales) => BarChartGroupData(
            x: monthlyData.indexOf(sales),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: sales.targetAmount,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF6CCC3F),
                borderRadius: BorderRadius.zero,
                toY: sales.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemGroupWiseAnalysisChartData(
    List<ProductGroupwiseData> productwiseSalesData,
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
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF6CCC3F),
                borderRadius: BorderRadius.zero,
                toY: sales.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemAnalysisChartData(
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
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF6CCC3F),
                borderRadius: BorderRadius.zero,
                toY: sales.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _openSOAgingChartData(
    List<OpenSOAgingData> openSOData,
  ) {
    return openSOData
        .map(
          (data) => BarChartGroupData(
            x: openSOData.indexOf(data),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF6CCC3F),
                borderRadius: BorderRadius.zero,
                toY: data.receivableAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  SideTitles get _bottomTitlesMonthWiseSO =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitles);

  Widget getBottomTitles(double val, TitleMeta meta) {
    String text = '';
    if (val.toInt() <= monthlySalesOrderList.soData.length - 1) {
      MonthlySalesOrderData monthlySoData = monthlySalesOrderList.soData
          .elementAt(val.toInt());
      text = monthlySoData.monthName;
      return Text(text.substring(0, 3));
    } else {
      return Text(text);
    }
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

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  void _scrollDown() {
    _verticalScrollController.animateTo(
      800,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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

  List<SODetailsList> filterSalesOrderList(
    List<SODetailsList> soList,
    List<Users> userNames, {
    String? regionalManager,
    String? salesManager,
    String? salesRep,
    String? customerCode,
    String? productGroupCode,
    String? productCode,
    String? agingCategory,
  }) {
    bool regionalManagerCondition = true;
    bool salesManagerCondition = true;
    bool agingCategoryCondition = true;
    List<SODetailsList> filteredSoList = [];

    double dueDays = 0, overDueDays = 0;
    if (agingCategory == "0-30") {
      dueDays = 30;
    } else if (agingCategory == "31-60") {
      dueDays = 60;
    } else if (agingCategory == "61-90") {
      dueDays = 90;
    } else if (agingCategory == "90+") {
      dueDays = 91;
    }
    for (var sale in soList) {
      if (regionalManager != null && regionalManager.isNotEmpty) {
        int? regionalManagerMenuId = userNames
            .firstWhere(
              (element) => element.menuName == regionalManager,
              orElse: () => Users(
                menuId: -1,
                menuName: '',
                subMenuId: -1,
                parentMenuId: -1,
                userLevel: -1,
              ),
            )
            .menuId;
        List<String> childMenuNames = userNames
            .where((element) => element.parentMenuId == regionalManagerMenuId)
            .map((user) => user.menuName)
            .toList();
        regionalManagerCondition =
            regionalManagerMenuId != -1 &&
            childMenuNames.contains(sale.salesManager);
      }

      if (salesManager != null && salesManager.isNotEmpty) {
        int? salesManagerMenuId = userNames
            .firstWhere(
              (element) => element.menuName == salesManager,
              orElse: () => Users(
                menuId: -1,
                menuName: '',
                subMenuId: -1,
                parentMenuId: -1,
                userLevel: -1,
              ),
            )
            .menuId;
        List<String> childMenuNames = userNames
            .where((element) => element.parentMenuId == salesManagerMenuId)
            .map((user) => user.menuName)
            .toList();
        salesManagerCondition =
            salesManagerMenuId != -1 && childMenuNames.contains(sale.salesRep);
      }

      if (agingCategory != null && agingCategory.isNotEmpty) {
        overDueDays = double.tryParse(sale.overDueDays) ?? 0;
        switch (dueDays) {
          case 30:
            if (overDueDays > dueDays) {
              agingCategoryCondition = false;
            }
          case 60:
            if (overDueDays > 30 && overDueDays <= dueDays) {
              agingCategoryCondition = false;
            }
          case 90:
            if (overDueDays > 60 && overDueDays <= dueDays) {
              agingCategoryCondition = false;
            }
          case 91:
            if (overDueDays >= dueDays) {
              agingCategoryCondition = false;
            }
          default:
            agingCategoryCondition = true;
        }
      }
      if (!regionalManagerCondition ||
          !salesManagerCondition ||
          !agingCategoryCondition) {
        continue; // Skip this sale if either regionalManager or salesManager condition fails
      }

      if ((salesRep == null || salesRep.isEmpty || sale.salesRep == salesRep) &&
          (customerCode == null ||
              customerCode.isEmpty ||
              sale.customerCode == customerCode) &&
          (productCode == null ||
              productCode.isEmpty ||
              sale.productCode == productCode) &&
          (productGroupCode == null ||
              productGroupCode.isEmpty ||
              sale.itemSubGroup == productGroupCode)) {
        filteredSoList.add(sale);
      }
    }
    return filteredSoList;
  }

  Future<void> _loadSODetails(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<SODetailsList> soDetailList = [];

    try {
      do {
        var body = {
          "FromDate": formatDate(addMonth(fiscalYearStartDate!, -3)),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}CRM_SOList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final List list = json['responseData'] ?? [];

          final newSalesOrder = list
              .map((e) => SODetailsList.fromJson(e))
              .toList();

          soDetailList.addAll(newSalesOrder);
          fetchedCount = newSalesOrder.length;
          index++;
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      final userLevelInt = int.tryParse(UserLevel) ?? 0;

      setState(() {
        context.read<SalesOrderListSoAnalysisBIProvider>().updateSalesOrder(
          soDetailList,
        );

        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();

        menuNames.insert(0, UserName);

        if (userLevelInt == 5) {
          SODetailList = soDetailList.toList();
        } else if (userLevelInt == 4) {
          SODetailList = soDetailList
              .where((e) => e.regionalManager == UserName)
              .toList();
        } else if (userLevelInt >= 2 && userLevelInt <= 3) {
          SODetailList = soDetailList
              .where((e) => menuNames.contains(e.salesManager))
              .toList();
        } else {
          SODetailList = soDetailList
              .where((e) => e.salesRep == UserName)
              .toList();
        }

        if (listOfString.isEmpty) {
          listOfString = List<String>.from(
            SODetailList.map((e) => e.soStatus).toSet(),
          );
        }
      });

      // FILTERING (unchanged logic)
      List<String> trueRSMOptions = (allCategoriesState['RSM'] ?? {}).entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      List<String> trueASMOptions = (allCategoriesState['ASM'] ?? {}).entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      List<String> trueTSMOptions = (allCategoriesState['TSM'] ?? {}).entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      List<String> trueStatusOptions = (allCategoriesState['Status'] ?? {})
          .entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      SODetailList = SODetailList.where((person) {
        return (trueRSMOptions.isEmpty ||
                trueRSMOptions.contains(person.regionalManager)) &&
            (trueASMOptions.isEmpty ||
                trueASMOptions.contains(person.salesManager)) &&
            (trueTSMOptions.isEmpty ||
                trueTSMOptions.contains(person.salesRep)) &&
            (trueStatusOptions.isEmpty ||
                trueStatusOptions.contains(person.soStatus));
      }).toList();

      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading SO data.",
      );
    }
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
    List<Map<String, dynamic>> list = iterableList
        .cast<Map<String, dynamic>>()
        .toList();
    List<Map<String, dynamic>> repList = [];

    double total = 0.0;
    if (userLevel == "1") {
      repList = list
          .where(
            (item) =>
                item['salesRep'] == userName &&
                item['financialYear'] == financialYear,
          )
          .toList();
    } else if (userLevel == "2" || userLevel == "3") {
      repList = list
          .where(
            (item) =>
                item['salesManager'] == userName &&
                item['financialYear'] == financialYear,
          )
          .toList();
    } else {
      repList = list
          .where(
            (item) =>
                item['regionalManager'] == userName &&
                item['financialYear'] == financialYear,
          )
          .toList();
    }

    if (repList.isNotEmpty) {
      List<String> availableMonths = repList.first.keys
          .where(
            (key) =>
                key != 'financialYear' &&
                key != 'salesRepCode' &&
                key != 'salesRep' &&
                key != 'salesManager' &&
                key != 'regionalManager',
          )
          .toList();
      for (var month in availableMonths) {
        total += calculateTotalForMonth(month, repList);
      }
    }
    return total;
  }

  Future<void> _loadMonthWiseSOAnalysisBarChartData() async {
    List<MonthlySalesOrderData> soDataList = [];

    DateTime now = DateTime.now();

    // Financial Year
    int fyStartYear = (now.month >= 4) ? now.year : now.year - 1;
    int fyEndYear = fyStartYear + 1;

    for (int i = 4; i <= 15; i++) {
      int month = i > 12 ? i - 12 : i;
      int year = month >= 4 ? fyStartYear : fyEndYear;

      String monthName = getMonthName(i);

      double monthlyTarget = 0;
      double monthlyCollection = 0;

      //-----------------------------
      // Previous 3 months
      //-----------------------------
      var dateRange = getLastThreeMonthsRange(month);

      DateTime prevThreeMonthFrom = dateRange['fromDate']!;
      DateTime prevThreeMonthTo = dateRange['endDate']!;

      var curMthSalesTarget = SODetailList.where((e) {
        DateTime soDate = getParsedDate(e.soDate);

        return soDate.isAtLeast(prevThreeMonthFrom) &&
            soDate.isAtMost(prevThreeMonthTo);
      });

      //-----------------------------
      // Current month
      //-----------------------------
      DateTime monthStart = DateTime(year, month, 1);
      DateTime monthEnd = DateTime(year, month + 1, 0);

      var monthlyCollectionList = SODetailList.where((e) {
        DateTime soDate = getParsedDate(e.soDate);

        return soDate.isAtLeast(monthStart) && soDate.isAtMost(monthEnd);
      });

      //-----------------------------
      // Totals
      //-----------------------------
      for (var item in monthlyCollectionList) {
        monthlyCollection += double.tryParse(item.orderValue) ?? 0;
      }

      for (var item in curMthSalesTarget) {
        monthlyTarget += double.tryParse(item.orderValue) ?? 0;
      }

      soDataList.add(
        MonthlySalesOrderData(
          monthName: monthName,
          salesOrderAmount: monthlyCollection,
          salesOrderTarget: monthlyTarget / 3,
        ),
      );
    }

    monthlySalesOrderList = MonthlySalesOrderList(soData: soDataList);
  }

  Future<void> _loadCustomerAnalysisBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String productGroupCode,
    String productCode,
    String touchedAgingCategory,
  ) async {
    List<CustomerWiseData> customerAnalysisDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String customerCode = "";
    String customerName = "";
    String productCode = "";
    double customerSales = 0.00;

    var monthlySoList = const Iterable.empty();

    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var dateRange = getLastThreeMonthsRange(currentDate!.month);
    prevThreethFromDate = dateRange['fromDate']!;
    prevThreeMthToDate = dateRange['endDate']!;

    var curMthSalesTarget = SODetailList.where((target) {
      // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
      DateTime invoiceDate = getParsedDate(target.soDate);
      return invoiceDate.isAtLeast(prevThreethFromDate!) &&
          invoiceDate.isAtMost(prevThreeMthToDate!);
    });
    double monthlyTarget = 0.00;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      monthlySoList = SODetailList.where((target) {
        DateTime invoiceDate = getParsedDate(target.soDate);
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        monthlySoList = SODetailList.where((target) {
          DateTime postingDate = getParsedDate(target.soDate);
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        monthlySoList = SODetailList.where((target) {
          DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        });
      }
    }
    monthlySoList = filterSalesOrderList(
      monthlySoList.cast<SODetailsList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );
    curMthSalesTarget = filterSalesOrderList(
      curMthSalesTarget.cast<SODetailsList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    monthlyTarget = 0;
    Set<String> processedCustomerCodes = {};
    for (var customer in monthlySoList.toList()) {
      if (!processedCustomerCodes.contains(customer.customerCode)) {
        customerCode = customer.customerCode;
        customerName = customer.customerName;

        for (var sales in monthlySoList.where(
          (sales) => sales.customerCode == customerCode,
        )) {
          customerSales += double.tryParse(sales.orderValue) ?? 0;
        }
        for (var target in curMthSalesTarget) {
          monthlyTarget += double.tryParse(target.orderValue) ?? 0;
        }

        customerAnalysisDataList.add(
          CustomerWiseData(
            customerCode: customerCode,
            customerName: customerName,
            saleAmount: customerSales,
            targetAmount: monthlyTarget / 3,
          ),
        );
        processedCustomerCodes.add(customer.customerCode);
      }
      customerSales = 0;
      customerCode = "";
      customerName = "";
    }

    customerAnalysisDataList.sort(
      (a, b) => b.saleAmount.compareTo(a.saleAmount),
    );
    customerAnalysisData = CustomerWiseSalesList(
      customerData: customerAnalysisDataList,
    );
  }

  Future<void> _loadRegionalManagerBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String productGroupCode,
    String productCode,
    String touchedAgingCategory,
  ) async {
    List<RsmwiseData> rsmwiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String rsmName = "";
    int rsmId = 0;
    int asmId = 0;
    double salesAmount = 0.00;
    double targetAmount = 0.00;

    var rsmSalesList = const Iterable.empty();
    var rsmSalesTargetList = const Iterable.empty();

    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var dateRange = getLastThreeMonthsRange(currentDate!.month);
    prevThreethFromDate = dateRange['fromDate']!;
    prevThreeMthToDate = dateRange['endDate']!;

    rsmSalesTargetList = SODetailList.where((target) {
      // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
      DateTime invoiceDate = getParsedDate(target.soDate);
      return invoiceDate.isAtLeast(prevThreethFromDate!) &&
          invoiceDate.isAtMost(prevThreeMthToDate!);
    });

    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      rsmSalesList = SODetailList.where((target) {
        DateTime invoiceDate = getParsedDate(target.soDate);
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        rsmSalesList = SODetailList.where((target) {
          DateTime invoiceDate = getParsedDate(target.soDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        rsmSalesList = SODetailList.where((target) {
          DateTime invoiceDate = getParsedDate(target.soDate);
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }

    List<SODetailsList> lstSales = rsmSalesList.cast<SODetailsList>().toList();
    rsmSalesList = filterSalesOrderList(
      lstSales,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    List<SODetailsList> lstSalesTrgt = rsmSalesTargetList
        .cast<SODetailsList>()
        .toList();
    rsmSalesTargetList = filterSalesOrderList(
      lstSalesTrgt,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    Set<String> processedRsmNames = {};
    List<AsmMenu> asmNames = [];
    List<String> tsmNames = [];
    if (int.tryParse(UserLevel)! > 3) {
      List<RsmMenu> rsmMenuNames = usersList
          .where(
            (element) => element.parentMenuId == 0 && element.userLevel == 3,
          )
          .map((user) => RsmMenu(user.menuName, user.menuId))
          .toList();
      for (var rsmMenu in rsmMenuNames) {
        if (!processedRsmNames.contains(rsmMenu.menuName)) {
          rsmName = rsmMenu.menuName;
          rsmId = rsmMenu.menuId;
          asmNames = usersList
              .where((element) => element.parentMenuId == rsmId)
              .map((user) => AsmMenu(user.menuName, user.menuId))
              .toList();
          for (var asmMenu in asmNames) {
            asmId = asmMenu.menuId;
            tsmNames = usersList
                .where((element) => element.parentMenuId == asmId)
                .map((user) => user.menuName)
                .toList();
            for (var sales in rsmSalesList.where(
              (tsmelement) => tsmNames.contains(tsmelement.salesRep),
            )) {
              salesAmount += double.tryParse(sales.orderValue) ?? 0;
            }
            for (var sales in rsmSalesTargetList.where(
              (tsmelement) => tsmNames.contains(tsmelement.salesRep),
            )) {
              targetAmount += double.tryParse(sales.orderValue) ?? 0;
            }
          }
          if (salesAmount + targetAmount > 0) {
            rsmwiseDataList.add(
              RsmwiseData(
                rsmName: rsmName,
                salesAmount: salesAmount,
                targetAmount: targetAmount / 3,
              ),
            );
          }
          processedRsmNames.add(rsmName);
        }
        targetAmount = 0;
        salesAmount = 0;
        rsmName = "";
      }
    }
    rsmwiseSalesList = RsmwiseSalesList(rsmwiseData: rsmwiseDataList);
    if (listOfRSM.isEmpty) {
      listOfRSM = List<String>.from(
        rsmSalesList.map((e) => e.regionalManager).toSet(),
      );
    }
  }

  Future<void> _loadSalesManagerBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String productGroupCode,
    String productCode,
    String touchedAgingCategory,
  ) async {
    List<AsmwiseData> asmwiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String asmName = "";
    int asmId = 0;
    double salesAmount = 0.00;
    double targetAmount = 0.00;

    var asmSalesList = const Iterable.empty();
    var asmSalesTargetList = const Iterable.empty();

    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var dateRange = getLastThreeMonthsRange(currentDate!.month);
    prevThreethFromDate = dateRange['fromDate']!;
    prevThreeMthToDate = dateRange['endDate']!;

    asmSalesTargetList = SODetailList.where((target) {
      // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
      DateTime invoiceDate = getParsedDate(target.soDate);
      return invoiceDate.isAtLeast(prevThreethFromDate!) &&
          invoiceDate.isAtMost(prevThreeMthToDate!);
    });

    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      asmSalesList = SODetailList.where((target) {
        // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
        DateTime invoiceDate = getParsedDate(target.soDate);
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        asmSalesList = SODetailList.where((target) {
          DateTime invoiceDate = getParsedDate(target.soDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        asmSalesList = SODetailList.where((target) {
          DateTime invoiceDate = getParsedDate(target.soDate);
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }

    List<SODetailsList> lstSales = asmSalesList.cast<SODetailsList>().toList();
    asmSalesList = filterSalesOrderList(
      lstSales,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    List<SODetailsList> lstSalesTrgt = asmSalesTargetList
        .cast<SODetailsList>()
        .toList();
    asmSalesTargetList = filterSalesOrderList(
      lstSalesTrgt,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    List<String> tsmNames = [];
    List<AsmMenu> asmMenuNames = usersList
        .where((element) => element.parentMenuId != 0 && element.userLevel == 2)
        .map((user) => AsmMenu(user.menuName, user.menuId))
        .toList();
    for (var asmMenu in asmMenuNames) {
      asmId = asmMenu.menuId;
      asmName = asmMenu.menuName;
      tsmNames = usersList
          .where((element) => element.parentMenuId == asmId)
          .map((user) => user.menuName)
          .toList();
      for (var sales in asmSalesList.where(
        (tsmelement) => tsmNames.contains(tsmelement.salesRep),
      )) {
        salesAmount += double.tryParse(sales.orderValue) ?? 0;
      }
      for (var target in asmSalesTargetList.where(
        (tsmelement) => tsmNames.contains(tsmelement.salesRep),
      )) {
        targetAmount += double.tryParse(target.orderValue) ?? 0;
      }
      if (salesAmount + targetAmount > 0) {
        asmwiseDataList.add(
          AsmwiseData(
            asmName: asmName,
            salesAmount: salesAmount,
            targetAmount: targetAmount / 3,
          ),
        );
      }
      targetAmount = 0;
      salesAmount = 0;
      asmName = "";
    }
    asmwiseDataList.sort((a, b) => a.salesAmount.compareTo(b.salesAmount));
    salesManagerData = AsmwiseSalesList(asmwiseData: asmwiseDataList);
    if (listOfASM.isEmpty) {
      listOfASM = List<String>.from(
        asmSalesList.map((e) => e.salesManager).toSet(),
      );
    }
  }

  Future<void> _loadSalesPersonBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String productGroupCode,
    String productCode,
    String touchedAgingCategory,
  ) async {
    List<TsmwiseData> tsmwiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String tsmName = "";
    double salesAmount = 0.00;
    double targetAmount = 0.00;

    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var dateRange = getLastThreeMonthsRange(currentDate!.month);
    prevThreethFromDate = dateRange['fromDate']!;
    prevThreeMthToDate = dateRange['endDate']!;

    var tsmSalesList = const Iterable.empty();
    var tsmSalesTargetList = const Iterable.empty();
    tsmSalesTargetList = SODetailList.where((target) {
      // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
      DateTime invoiceDate = getParsedDate(target.soDate);
      return invoiceDate.isAtLeast(prevThreethFromDate!) &&
          invoiceDate.isAtMost(prevThreeMthToDate!);
    });

    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      tsmSalesList = SODetailList.where((target) {
        // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
        DateTime invoiceDate = getParsedDate(target.soDate);
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        tsmSalesList = SODetailList.where((target) {
          // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
          DateTime invoiceDate = getParsedDate(target.soDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        tsmSalesList = SODetailList.where((target) {
          // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
          DateTime invoiceDate = getParsedDate(target.soDate);
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }

    List<SODetailsList> lstSales = tsmSalesList.cast<SODetailsList>().toList();
    tsmSalesList = filterSalesOrderList(
      lstSales,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    List<SODetailsList> lstSalesTrgt = tsmSalesList
        .cast<SODetailsList>()
        .toList();
    tsmSalesTargetList = filterSalesOrderList(
      lstSalesTrgt,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    Set<String> processedTsmNames = {};
    for (var tsm in tsmSalesList.toList()) {
      if (!processedTsmNames.contains(tsm.salesRep)) {
        tsmName = tsm.salesRep;
        for (var sales in tsmSalesList.where(
          (tsmelement) => tsmelement.salesRep == tsmName,
        )) {
          salesAmount += double.tryParse(sales.orderValue) ?? 0;
        }
        for (var target in tsmSalesTargetList) {
          targetAmount += double.tryParse(target.orderValue) ?? 0;
        }
        tsmwiseDataList.add(
          TsmwiseData(
            tsmName: tsmName,
            salesAmount: salesAmount,
            targetAmount: targetAmount / 3,
          ),
        );
        processedTsmNames.add(tsmName);
      }
      targetAmount = 0;
      salesAmount = 0;
      tsmName = "";
    }
    tsmwiseDataList.sort((a, b) => a.salesAmount.compareTo(b.salesAmount));
    salesPersonData = TsmwiseSalesList(tsmwiseData: tsmwiseDataList);
    if (listOfTSM.isEmpty) {
      listOfTSM = List<String>.from(
        tsmSalesList.map((e) => e.salesRep).toSet(),
      );
    }
  }

  Future<void> _loadItemGroupWiseSalesBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String productGroupCode,
    String productCode,
    String touchedAgingCategory,
  ) async {
    List<ProductGroupwiseData> productGroupwiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String productGroupName = "";
    double productSales = 0.00;
    double productTarget = 0.00;

    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var dateRange = getLastThreeMonthsRange(currentDate!.month);
    prevThreethFromDate = dateRange['fromDate']!;
    prevThreeMthToDate = dateRange['endDate']!;

    var curMthSalesTarget = SODetailList.where((target) {
      // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
      DateTime invoiceDate = getParsedDate(target.soDate);
      return invoiceDate.isAtLeast(prevThreethFromDate!) &&
          invoiceDate.isAtMost(prevThreeMthToDate!);
    });

    var productSalesList = const Iterable.empty();
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      productSalesList = SODetailList.where((target) {
        // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
        DateTime invoiceDate = getParsedDate(target.soDate);
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        productSalesList = SODetailList.where((target) {
          // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
          DateTime invoiceDate = getParsedDate(target.soDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        productSalesList = SODetailList.where((target) {
          // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
          DateTime invoiceDate = getParsedDate(target.soDate);
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }

    productSalesList = filterSalesOrderList(
      productSalesList.cast<SODetailsList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );
    curMthSalesTarget = filterSalesOrderList(
      curMthSalesTarget.cast<SODetailsList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    Set<String> processedProductGroups = {};
    for (var product in productSalesList.toList()) {
      if (!processedProductGroups.contains(product.itemSubGroup)) {
        productGroupName = product.itemSubGroup;
        for (var target in productSalesList.where(
          (prdelement) => prdelement.itemSubGroup == productGroupName,
        )) {
          productSales += double.tryParse(target.orderValue) ?? 0;
        }
        for (var target in curMthSalesTarget.where(
          (element) => element.itemSubGroup == productGroupName,
        )) {
          productTarget += double.tryParse(target.orderValue) ?? 0;
        }
        productGroupwiseDataList.add(
          ProductGroupwiseData(
            productGroupName: productGroupName,
            salesAmount: productSales,
            targetAmount: productTarget / 3,
          ),
        );
        processedProductGroups.add(productGroupName);
      }
      productSales = 0;
      productTarget = 0;
      productGroupName = "";
    }

    productGroupwiseDataList.sort(
      (a, b) => b.salesAmount.compareTo(a.salesAmount),
    );
    itemGroupWiseData = ProductGroupwiseSalesList(
      productGroupData: productGroupwiseDataList,
    );
  }

  Future<void> _loadItemAnalysisSalesBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String productGroupCode,
    String productCode,
    String touchedAgingCategory,
  ) async {
    List<ProductwiseData> productwiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String productCode = "";
    String productName = "";
    double productSales = 0.00;
    double productTarget = 0.00;

    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var dateRange = getLastThreeMonthsRange(currentDate!.month);
    prevThreethFromDate = dateRange['fromDate']!;
    prevThreeMthToDate = dateRange['endDate']!;

    var curMthSalesTarget = SODetailList.where((target) {
      // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
      DateTime invoiceDate = getParsedDate(target.soDate);
      return invoiceDate.isAtLeast(prevThreethFromDate!) &&
          invoiceDate.isAtMost(prevThreeMthToDate!);
    });

    var productSalesList = const Iterable.empty();
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      productSalesList = SODetailList.where((target) {
        // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
        DateTime invoiceDate = getParsedDate(target.soDate);
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        productSalesList = SODetailList.where((target) {
          // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
          DateTime invoiceDate = getParsedDate(target.soDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        productSalesList = SODetailList.where((target) {
          // DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
          DateTime invoiceDate = getParsedDate(target.soDate);
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }

    productSalesList = filterSalesOrderList(
      productSalesList.cast<SODetailsList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );
    curMthSalesTarget = filterSalesOrderList(
      curMthSalesTarget.cast<SODetailsList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    Set<String> processedProductCodes = {};
    for (var product in productSalesList.toList()) {
      if (!processedProductCodes.contains(product.productCode)) {
        productCode = product.productCode;
        productName = product.productName;
        for (var target in productSalesList.where(
          (prdelement) => prdelement.productCode == productCode,
        )) {
          productSales += double.tryParse(target.orderValue) ?? 0;
        }
        for (var target in curMthSalesTarget.where(
          (element) => element.productCode == productCode,
        )) {
          productTarget += double.tryParse(target.orderValue) ?? 0;
        }

        productwiseDataList.add(
          ProductwiseData(
            productCode: productCode,
            productName: productName,
            salesAmount: productSales,
            targetAmount: productTarget / 3,
          ),
        );
        processedProductCodes.add(product.productCode);
      }
      productSales = 0;
      productTarget = 0;
      productCode = "";
      productName = "";
    }

    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));
    itemAnalysisData = ProductwiseSalesList(productData: productwiseDataList);
  }

  Future<void> _loadOpenSOAgingBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String productGroupCode,
    String productCode,
    String touchedAgingCategory,
  ) async {
    List<OpenSOAgingData> openSOAgingDataList = [];

    var soAgingList = const Iterable.empty();
    setState(() {
      soAgingList = SODetailList.where(
        (element) => element.soStatus == "Open",
      ).toList();
    });
    double amount0to30 = 0.0;
    double amount31to60 = 0.0;
    double amount61to90 = 0.0;
    double amount91a = 0.0;
    double maxY = 0;
    soAgingList = filterSalesOrderList(
      soAgingList.cast<SODetailsList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    for (var product in soAgingList.toList()) {
      var overDueDays = product.overDueDays;
      var orderValue = product.orderValue;

      if (overDueDays != null && orderValue != null) {
        var parsedOverDueDays = double.tryParse(overDueDays) ?? 0;
        var parsedOrderValue = double.tryParse(orderValue) ?? 0;
        if (parsedOverDueDays <= 30) {
          amount0to30 += parsedOrderValue;
        } else if (parsedOverDueDays >= 31 && parsedOverDueDays <= 60) {
          amount31to60 += parsedOrderValue;
        } else if (parsedOverDueDays >= 61 && parsedOverDueDays <= 90) {
          amount61to90 += parsedOrderValue;
        } else if (parsedOverDueDays >= 91) {
          amount91a += parsedOrderValue;
        }
      }
    }
    if (amount0to30 > maxY) {
      maxY = amount0to30;
    }
    if (amount31to60 > maxY) {
      maxY = amount31to60;
    }
    if (amount61to90 > maxY) {
      maxY = amount61to90;
    }
    if (amount91a > maxY) {
      maxY = amount91a;
    }
    maxY = ((maxY ~/ 100000) + 1) * 100000;
    openSOAgingDataList.add(
      OpenSOAgingData(
        receivableAmount: amount0to30,
        percentage: 0,
        group: "0-30",
        maxY: maxY,
      ),
    );
    openSOAgingDataList.add(
      OpenSOAgingData(
        receivableAmount: amount31to60,
        percentage: 0,
        group: "31-60",
        maxY: maxY,
      ),
    );
    openSOAgingDataList.add(
      OpenSOAgingData(
        receivableAmount: amount61to90,
        percentage: 0,
        group: "61-90",
        maxY: maxY,
      ),
    );
    openSOAgingDataList.add(
      OpenSOAgingData(
        receivableAmount: amount91a,
        percentage: 0,
        group: "90+",
        maxY: maxY,
      ),
    );
    openSoAgingData = OpenSOAgingList(soAgingData: openSOAgingDataList);
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

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;

      ytdSalesList = YTDSalesList(ytdData: []);
      customerAnalysisData = CustomerWiseSalesList(customerData: []);
      salesManagerData = AsmwiseSalesList(asmwiseData: []);
      salesPersonData = TsmwiseSalesList(tsmwiseData: []);
      rsmwiseSalesList = RsmwiseSalesList(rsmwiseData: []);
      itemGroupWiseData = ProductGroupwiseSalesList(productGroupData: []);
      itemAnalysisData = ProductwiseSalesList(productData: []);
      openSoAgingData = OpenSOAgingList(soAgingData: []);
      SODetailList = [];
      monthlySalesOrderList = MonthlySalesOrderList(soData: []);
      touchedMonthIndex = 0;
      touchedRegionalManager = "";
      touchedSalesManager = "";
      touchedSalesRep = "";
      touchedCustomer = "";
      touchedProduct = "";
      touchedProductGroup = "";
      touchedState = "";
    });
  }

  Future<void> removeFilter() async {
    touchedMonthIndex = 0;
    touchedRegionalManager = "";
    touchedSalesManager = "";
    touchedSalesRep = "";
    touchedCustomer = "";
    touchedProduct = "";
    touchedProductGroup = "";
    touchedState = "";
    touchedAgingCategory = "";
    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;
    LoadDates();
    final prefs = await SharedPreferences.getInstance();
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    setState(() {
      chartDataLoaded = false;
      clearVariables();
      LoadDates();
      allCategoriesState.forEach((category, options) {
        options.updateAll((key, value) => false);
      });
      allCategoriesState.clear();
      loadDataFuture = loadData("");
    });
    chartDataLoaded = true;
  }

  Future<void> loadDataWithFilter(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String productGroupCode,
    String productCode,
    String touchedAgingCategory,
  ) async {
    LoadDates();
    final prefs = await SharedPreferences.getInstance();
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    showDrillDownChart = true;
    showProductSaleChart = true;
    await Future.wait([
      _loadMonthWiseSOAnalysisBarChartData(),
      _loadCustomerAnalysisBarChartData(
        monthIndex,
        regionalManager,
        salesManager,
        salesRep,
        customerCode,
        productGroupCode,
        productCode,
        touchedAgingCategory,
      ),
      if (UserLevel != "1") ...[
        _loadSalesPersonBarChartData(
          monthIndex,
          regionalManager,
          salesManager,
          salesRep,
          customerCode,
          productGroupCode,
          productCode,
          touchedAgingCategory,
        ),
        _loadSalesManagerBarChartData(
          monthIndex,
          regionalManager,
          salesManager,
          salesRep,
          customerCode,
          productGroupCode,
          productCode,
          touchedAgingCategory,
        ),
        _loadRegionalManagerBarChartData(
          monthIndex,
          regionalManager,
          salesManager,
          salesRep,
          customerCode,
          productGroupCode,
          productCode,
          touchedAgingCategory,
        ),
      ],
      _loadItemGroupWiseSalesBarChartData(
        monthIndex,
        regionalManager,
        salesManager,
        salesRep,
        customerCode,
        productGroupCode,
        productCode,
        touchedAgingCategory,
      ),
      _loadItemAnalysisSalesBarChartData(
        monthIndex,
        regionalManager,
        salesManager,
        salesRep,
        customerCode,
        productGroupCode,
        productCode,
        touchedAgingCategory,
      ),
      _loadOpenSOAgingBarChartData(
        monthIndex,
        regionalManager,
        salesManager,
        salesRep,
        customerCode,
        productGroupCode,
        productCode,
        touchedAgingCategory,
      ),
    ]);
    setState(() {
      chartDataLoaded = true;
    });
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
    await Future.wait([
      _loadUserList(
        userId,
        userJwtToken,
        userMailID,
        int.tryParse(userLevel) ?? 0,
      ),

      _loadUserListForFilter(
        userId,
        userJwtToken,
        userMailID,
        int.tryParse(userLevel) ?? 0,
      ),
    ]);

    await _loadSODetails(userName, userLevel);

    await Future.wait([
      _loadMonthWiseSOAnalysisBarChartData(),
      _loadCustomerAnalysisBarChartData(0, "", "", "", "", "", "", ""),
      if (UserLevel != "1") ...[
        _loadSalesPersonBarChartData(0, "", "", "", "", "", "", ""),
        _loadSalesManagerBarChartData(0, "", "", "", "", "", "", ""),
        _loadRegionalManagerBarChartData(0, "", "", "", "", "", "", ""),
      ],
      _loadItemGroupWiseSalesBarChartData(0, "", "", "", "", "", "", ""),
      _loadItemAnalysisSalesBarChartData(0, "", "", "", "", "", "", ""),
      _loadOpenSOAgingBarChartData(0, "", "", "", "", "", "", ""),
    ]);
    setState(() {
      filterOptions = [listOfRSM, listOfASM, listOfTSM, listOfString, []];

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

  // Map<String, DateTime> getLastThreeMonthsRange(int monthIndex) {
  //   // Ensure the month index is valid (1 to 12)
  //   if (monthIndex < 1 || monthIndex > 12) {
  //     throw ArgumentError('Invalid month index. Must be between 1 and 12.');
  //   }

  //   DateTime now = DateTime.now();

  //   // Financial year start (April to March)
  //   int financialYearStart = (now.month >= 4) ? now.year : now.year - 1;

  //   // Determine the year for the given month
  //   int yearForMonth = (monthIndex >= 4)
  //       ? financialYearStart
  //       : financialYearStart + 1;

  //   // Adjust the start month to handle wrapping to the previous year
  //   int startMonthIndex = monthIndex - 3;
  //   int startYear = yearForMonth;
  //   if (startMonthIndex < 1) {
  //     startMonthIndex += 12; // Wrap to the previous year
  //     startYear--; // Adjust the year
  //   }

  //   // Calculate start and end dates
  //   DateTime startDate = DateTime(startYear, startMonthIndex, 1);
  //   DateTime endDate = DateTime(yearForMonth, monthIndex, 0);

  //   return {'fromDate': startDate, 'endDate': endDate};
  // }

  Map<String, DateTime> getLastThreeMonthsRange(int monthIndex) {
    if (monthIndex < 1 || monthIndex > 12) {
      throw ArgumentError('Invalid month index. Must be between 1 and 12.');
    }

    DateTime now = DateTime.now();

    // Financial Year
    int fyStartYear = (now.month >= 4) ? now.year : now.year - 1;
    int fyEndYear = fyStartYear + 1;

    // Month belongs to which year?
    int yearForMonth = monthIndex >= 4 ? fyStartYear : fyEndYear;

    // Current month start
    DateTime currentMonthStart = DateTime(yearForMonth, monthIndex, 1);

    // Previous 3 months start
    DateTime fromDate = DateTime(
      currentMonthStart.year,
      currentMonthStart.month - 3,
      1,
    );

    // Last day of previous month
    DateTime endDate = DateTime(
      currentMonthStart.year,
      currentMonthStart.month,
      0,
    );

    return {'fromDate': fromDate, 'endDate': endDate};
  }

  Future<void> generateMonthWiseSOAnalysisExcel(
    MonthlySalesOrderList monthlySalesList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'MonthWiseSOAnalysis',
      headers: ['Month', 'SO Amount', 'SO Target', 'Percentage', 'Difference'],
      rows: monthlySalesList.soData
          .map(
            (monthlyData) => [
              monthlyData.monthName,
              monthlyData.salesOrderAmount,
              monthlyData.salesOrderTarget,
              (monthlyData.salesOrderTarget == 0
                      ? 0
                      : (monthlyData.salesOrderAmount /
                                monthlyData.salesOrderTarget) *
                            100)
                  .ceil()
                  .toStringAsFixed(0),
              monthlyData.salesOrderAmount - monthlyData.salesOrderTarget,
            ],
          )
          .toList(),
      fileName: 'monthly_so_analysis.xlsx',
      amountColumns: [2, 3, 5],
      addTotalRow: true,
      reportTitle: 'Sales - MonthWise SO Analysis',
    );
  }

  Future<void> generateMonthWiseSOAnalysisPDF(
    MonthlySalesOrderList monthlySalesList,
  ) async {
    await reportService.generatePDF(
      title: 'MonthWiseSOAnalysis',
      headers: ['Month', 'SO Amount', 'SO Target', 'Percentage', 'Difference'],
      rows: monthlySalesList.soData
          .map(
            (monthlyData) => [
              monthlyData.monthName,
              monthlyData.salesOrderAmount,
              monthlyData.salesOrderTarget,
              (monthlyData.salesOrderTarget == 0
                      ? 0
                      : (monthlyData.salesOrderAmount /
                                monthlyData.salesOrderTarget) *
                            100)
                  .ceil()
                  .toStringAsFixed(0),
              monthlyData.salesOrderAmount - monthlyData.salesOrderTarget,
            ],
          )
          .toList(),
      fileName: 'monthly_so_analysis.pdf',
      amountColumns: [2, 3, 5],
    );
  }

  Future<void> generateCustomerAnalysisSOExcel(
    CustomerWiseSalesList customerWiseSalesList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'CustomerWiseSOAnalysis',
      headers: [
        'Customer Name',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: customerWiseSalesList.customerData
          .map(
            (customerData) => [
              customerData.customerName,
              customerData.saleAmount,
              customerData.targetAmount,
              ((customerData.saleAmount / customerData.targetAmount == 0
                          ? customerData.saleAmount
                          : customerData.targetAmount) *
                      100)
                  .ceil()
                  .toStringAsFixed(0),
              customerData.saleAmount - customerData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'customer_wise_so_analysis.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - Customer Wise SO Analysis',
    );
  }

  Future<void> generateCustomerAnalysisSOPDF(
    CustomerWiseSalesList customerWiseSalesList,
  ) async {
    await reportService.generatePDF(
      title: 'CustomerWiseSOAnalysis',
      headers: [
        'Customer Name',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: customerWiseSalesList.customerData
          .map(
            (customerData) => [
              customerData.customerName,
              customerData.saleAmount,
              customerData.targetAmount,
              ((customerData.saleAmount / customerData.targetAmount == 0
                          ? customerData.saleAmount
                          : customerData.targetAmount) *
                      100)
                  .ceil()
                  .toStringAsFixed(0),
              customerData.saleAmount - customerData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'customer_wise_so_analysis.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateRsmSalesExcel(RsmwiseSalesList rsmwiseSalesList) async {
    await reportService.generateExcel(
      sheetName: 'RSMWiseSOAnalysis',
      headers: [
        'RSM Name',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: rsmwiseSalesList.rsmwiseData
          .map(
            (rsmData) => [
              rsmData.rsmName,
              rsmData.salesAmount,
              rsmData.targetAmount,
              ((rsmData.salesAmount / rsmData.targetAmount) * 100)
                  .ceil()
                  .toStringAsFixed(0),
              rsmData.salesAmount - rsmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'rsm_wise_so_analysis.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - RSM Wise SO Analysis',
    );
  }

  Future<void> generateRsmSalesPDF(RsmwiseSalesList rsmwiseSalesList) async {
    await reportService.generatePDF(
      title: 'RSMWiseSOAnalysis',
      headers: [
        'RSM Name',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: rsmwiseSalesList.rsmwiseData
          .map(
            (rsmData) => [
              rsmData.rsmName,
              rsmData.salesAmount,
              rsmData.targetAmount,
              ((rsmData.salesAmount / rsmData.targetAmount) * 100)
                  .ceil()
                  .toStringAsFixed(0),
              rsmData.salesAmount - rsmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'rsm_wise_so_analysis.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateSalesManagerAnalysisSOExcel(
    AsmwiseSalesList asmwiseSalesList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ASMWiseSOAnalysis',
      headers: [
        'ASM Name',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: asmwiseSalesList.asmwiseData
          .map(
            (asmData) => [
              asmData.asmName,
              asmData.salesAmount,
              asmData.targetAmount,
              ((asmData.salesAmount / asmData.targetAmount) * 100)
                  .ceil()
                  .toStringAsFixed(0),
              asmData.salesAmount - asmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'asm_wise_so_analysis.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - ASM Wise SO Analysis',
    );
  }

  Future<void> generateSalesManagerAnalysisSOPDF(
    AsmwiseSalesList asmwiseSalesList,
  ) async {
    await reportService.generatePDF(
      title: 'ASMWiseSOAnalysis',
      headers: [
        'ASM Name',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: asmwiseSalesList.asmwiseData
          .map(
            (asmData) => [
              asmData.asmName,
              asmData.salesAmount,
              asmData.targetAmount,
              ((asmData.salesAmount / asmData.targetAmount) * 100)
                  .ceil()
                  .toStringAsFixed(0),
              asmData.salesAmount - asmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'asm_wise_so_analysis.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateSalesPersonAnalysisSOExcel(
    TsmwiseSalesList salesPersonData,
  ) async {
    await reportService.generateExcel(
      sheetName: 'TSMWiseSOAnalysis',
      headers: [
        'TSM Name',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: salesPersonData.tsmwiseData
          .map(
            (tsmData) => [
              tsmData.tsmName,
              tsmData.salesAmount,
              tsmData.targetAmount,
              ((tsmData.salesAmount / tsmData.targetAmount) * 100)
                  .ceil()
                  .toStringAsFixed(0),
              tsmData.salesAmount - tsmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'tsm_wise_so_analysis.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - TSM Wise SO Analysis',
    );
  }

  Future<void> generateSalesPersonAnalysisSOPDF(
    TsmwiseSalesList salesPersonData,
  ) async {
    await reportService.generatePDF(
      title: 'TSMWiseSOAnalysis',
      headers: [
        'TSM Name',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: salesPersonData.tsmwiseData
          .map(
            (tsmData) => [
              tsmData.tsmName,
              tsmData.salesAmount,
              tsmData.targetAmount,
              ((tsmData.salesAmount / tsmData.targetAmount) * 100)
                  .ceil()
                  .toStringAsFixed(0),
              tsmData.salesAmount - tsmData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'tsm_wise_so_analysis.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateItemGroupWiseAnalysisSOExcel(
    ProductGroupwiseSalesList itemGroupWiseData,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ItemGroupWiseSOAnalysis',
      headers: [
        'Product Group',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: itemGroupWiseData.productGroupData
          .map(
            (groupData) => [
              groupData.productGroupName,
              groupData.salesAmount,
              groupData.targetAmount,
              ((groupData.salesAmount / groupData.targetAmount == 0
                          ? groupData.salesAmount
                          : groupData.targetAmount) *
                      100)
                  .ceil()
                  .toStringAsFixed(0),
              groupData.salesAmount - groupData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'item_group_wise_so_analysis.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - Item Group Wise SO Analysis',
    );
  }

  Future<void> generateItemGroupWiseAnalysisSOPDF(
    ProductGroupwiseSalesList itemGroupWiseData,
  ) async {
    await reportService.generatePDF(
      title: 'ItemGroupWiseSOAnalysis',
      headers: [
        'Product Group',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: itemGroupWiseData.productGroupData
          .map(
            (groupData) => [
              groupData.productGroupName,
              groupData.salesAmount,
              groupData.targetAmount,
              ((groupData.salesAmount / groupData.targetAmount == 0
                          ? groupData.salesAmount
                          : groupData.targetAmount) *
                      100)
                  .ceil()
                  .toStringAsFixed(0),
              groupData.salesAmount - groupData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'item_group_wise_so_analysis.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateItemAnalysisSOExcel(
    ProductwiseSalesList itemAnalysisData,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ItemWiseSOAnalysis',
      headers: [
        'Product Name',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: itemAnalysisData.productData
          .map(
            (itemData) => [
              itemData.productName,
              itemData.salesAmount,
              itemData.targetAmount,
              ((itemData.salesAmount / itemData.targetAmount == 0
                          ? itemData.salesAmount
                          : itemData.targetAmount) *
                      100)
                  .ceil()
                  .toStringAsFixed(0),
              itemData.salesAmount - itemData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'item_wise_so_analysis.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Sales - Item Wise SO Analysis',
    );
  }

  Future<void> generateItemAnalysisSOPDF(
    ProductwiseSalesList itemAnalysisData,
  ) async {
    await reportService.generatePDF(
      title: 'ItemWiseSOAnalysis',
      headers: [
        'Product Name',
        'Sales Amount',
        'Sales Target',
        'Percentage',
        'Difference',
      ],
      rows: itemAnalysisData.productData
          .map(
            (itemData) => [
              itemData.productName,
              itemData.salesAmount,
              itemData.targetAmount,
              ((itemData.salesAmount / itemData.targetAmount == 0
                          ? itemData.salesAmount
                          : itemData.targetAmount) *
                      100)
                  .ceil()
                  .toStringAsFixed(0),
              itemData.salesAmount - itemData.targetAmount,
            ],
          )
          .toList(),
      fileName: 'item_wise_so_analysis.pdf',
      amountColumns: [2, 3, 4, 5],
    );
  }

  Future<void> generateOpenSOAgingExcel(OpenSOAgingList agingData) async {
    await reportService.generateExcel(
      sheetName: 'OpenSOAgeingAnalysis',
      headers: ['Ageing Category', 'Amount'],
      rows: agingData.soAgingData
          .map((agingData) => [agingData.group, agingData.receivableAmount])
          .toList(),
      fileName: 'open_so_ageing_analysis.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Sales - Open SO Ageing Analysis',
    );
  }

  Future<void> generateOpenSOAgingPDF(OpenSOAgingList agingData) async {
    await reportService.generatePDF(
      title: 'OpenSOAgeingAnalysis',
      headers: ['Ageing Category', 'Amount'],
      rows: agingData.soAgingData
          .map((agingData) => [agingData.group, agingData.receivableAmount])
          .toList(),
      fileName: 'open_so_ageing_analysis.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateSalesAnalysisYTDExcel() async {
    await reportService.generateExcel(
      sheetName: 'SOAnalysisYTD',
      headers: [
        'PO Date',
        'Customer Name',
        'Sales Rep',
        'Sales Manager',
        'Item Sub Group',
        'Product Name',
        'Rate',
        'Order Quantity',
        'Dispatch Quantity',
        'Pending Quantity',
        'Pending Value',
        'Remark',
      ],
      rows: SODetailList.map(
        (ytdData) => [
          ytdData.poDate,
          ytdData.customerName,
          ytdData.salesRep,
          ytdData.salesManager,
          ytdData.itemSubGroup,
          ytdData.productName,
          ytdData.rate,
          ytdData.orderQuantity,
          ytdData.dispatchQuantity,
          ytdData.pendingQuantity,
          ytdData.pendingValue,
          ytdData.remark,
        ],
      ).toList(),
      fileName: 'ytd_so_analysis.xlsx',
      amountColumns: [8, 9, 10, 11],
      addTotalRow: true,
      reportTitle: 'Sales - SO Analysis(YTD)',
    );
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  void resetFinanceReceivablesOptions() {
    setState(() {
      savedFinanceReceivablesOptions = List.from(
        selectedFinanceReceivablesOptions,
      );
    });
  }

  Future<void> _dateFilterTarget(
    String UserName,
    String UserLevel,
    bool FromFilter,
  ) async {
    setState(() {
      List<String> menuNames = usersList
          .where((element) => element.parentMenuId == 0)
          .map((user) => user.menuName)
          .toList();
      menuNames.insert(0, UserName);
      context.read<SalesOrderListSoAnalysisBIProvider>().updateSalesOrder(
        SODetailList,
      );

      SODetailList = SODetailList.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.soDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();
    });
  }

  Future<void> filterFunction() async {
    setState(() {
      chartDataLoaded = false;
    });
    _dateFilterTarget("", "", false);
    await Future.wait([
      _loadMonthWiseSOAnalysisBarChartData(),
      _loadCustomerAnalysisBarChartData(0, "", "", "", "", "", "", ""),
      if (UserLevel != "1") ...[
        _loadSalesPersonBarChartData(0, "", "", "", "", "", "", ""),
        _loadSalesManagerBarChartData(0, "", "", "", "", "", "", ""),
        _loadRegionalManagerBarChartData(0, "", "", "", "", "", "", ""),
      ],
      _loadItemGroupWiseSalesBarChartData(0, "", "", "", "", "", "", ""),
      _loadItemAnalysisSalesBarChartData(0, "", "", "", "", "", "", ""),
      _loadOpenSOAgingBarChartData(0, "", "", "", "", "", "", ""),
    ]);
    List<String> trueRSMOptions = (allCategoriesState['RSM'] ?? {}).entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    List<String> trueASMOptions = (allCategoriesState['ASM'] ?? {}).entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    List<String> trueTSMOptions = (allCategoriesState['TSM'] ?? {}).entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    List<String> trueStatusOptions = (allCategoriesState['Status'] ?? {})
        .entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    //List<SODetailsList> filteredList = [];
    SODetailList = SODetailList.where((person) {
      return (trueRSMOptions.isEmpty ||
              trueRSMOptions.contains(person.regionalManager)) &&
          (trueASMOptions.isEmpty ||
              trueASMOptions.contains(person.salesManager)) &&
          (trueTSMOptions.isEmpty ||
              trueTSMOptions.contains(person.salesRep)) &&
          (trueStatusOptions.isEmpty ||
              trueStatusOptions.contains(person.soStatus));
    }).toList();

    setState(() {
      filterOptions = [listOfRSM, listOfASM, listOfTSM, listOfString, []];

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

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _monthlySOHorizontalController = ScrollController();
  final ScrollController _customerHorizontalController = ScrollController();
  final ScrollController _regionalManagerHorizontalController =
      ScrollController();
  final ScrollController _salesManagerHorizontalController = ScrollController();
  final ScrollController _salesPersonHorizontalController = ScrollController();
  final ScrollController _itemGroupWiseHorizontalController =
      ScrollController();
  final ScrollController _itemWiseHorizontalController = ScrollController();
  final ScrollController _soAgeingHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    chartDataLoaded = false;
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
      toDateFilter = currentDate;
      fromDateFilter = fiscalYearStartDate;
    }

    filterOptions = [listOfRSM, listOfASM, listOfTSM, listOfString, []];

    selectedFinanceReceivablesOptions = filterOptions
        .map((options) => List<bool>.filled(options.length, false))
        .toList();

    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _monthlySOHorizontalController.dispose();
    _customerHorizontalController.dispose();
    _regionalManagerHorizontalController.dispose();
    _salesManagerHorizontalController.dispose();
    _salesPersonHorizontalController.dispose();
    _itemGroupWiseHorizontalController.dispose();
    _itemWiseHorizontalController.dispose();
    _soAgeingHorizontalController.dispose();
    chartDataLoaded = false;

    monthlySalesOrderList = MonthlySalesOrderList(soData: []);
    customerAnalysisData = CustomerWiseSalesList(customerData: []);
    salesManagerData = AsmwiseSalesList(asmwiseData: []);
    salesPersonData = TsmwiseSalesList(tsmwiseData: []);
    rsmwiseSalesList = RsmwiseSalesList(rsmwiseData: []);
    itemGroupWiseData = ProductGroupwiseSalesList(productGroupData: []);
    itemAnalysisData = ProductwiseSalesList(productData: []);
    openSoAgingData = OpenSOAgingList(soAgingData: []);
    SODetailList = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        const SizedBox(width: 5),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'excel') {
                              showLoaderDialog(context);

                              try {
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );

                                await generateSalesAnalysisYTDExcel();
                              } finally {
                                if (mounted && Navigator.canPop(context)) {
                                  Navigator.pop(context); // Close loader
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'excel',
                              child: Text("Download Excel"),
                            ),
                          ],
                        ),

                        // PopupMenuButton(
                        //   onSelected: (value) {},
                        //   itemBuilder: (BuildContext bc) {
                        //     return [
                        //       PopupMenuItem(
                        //         onTap: () {
                        //           setState(() {
                        //             showLoaderDialog(context);
                        //             generateSalesAnalysisYTDExcel();
                        //             if (YtdSOBarChartData == true) {
                        //               Navigator.pop(context);
                        //             }
                        //           });
                        //         },
                        //         child: const Row(
                        //           children: [Text("Download Excel")],
                        //         ),
                        //       ),
                        //     ];
                        //   },
                        // ),
                      ],
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Monthwise SO Analysis',
                    spacing: 20,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF6CCC3F),
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
                          await generateMonthWiseSOAnalysisExcel(
                            monthlySalesOrderList,
                          );
                        },
                        child: const Text('Download Excel'),
                      ),

                      PopupMenuItem(
                        onTap: () async {
                          await generateMonthWiseSOAnalysisPDF(
                            monthlySalesOrderList,
                          );
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _monthlyWiseSOAnalysis(),
                  ),
                ),

                Visibility(
                  visible: customerAnalysisData.customerData.isNotEmpty,
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
                            color: const Color(0xFF6CCC3F),
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
                            generateCustomerAnalysisSOExcel(
                              customerAnalysisData,
                            );
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            generateCustomerAnalysisSOPDF(customerAnalysisData);
                          },
                          child: const Text("Download PDF"),
                        ),
                      ],
                      child: _customerAnalysis(),
                    ),
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
                            color: const Color(0xFF6CCC3F),
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
                  visible: salesManagerData.asmwiseData.isNotEmpty,
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
                            color: const Color(0xFF6CCC3F),
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
                            await generateSalesManagerAnalysisSOExcel(
                              salesManagerData,
                            );
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            await generateSalesManagerAnalysisSOPDF(
                              salesManagerData,
                            );
                          },
                          child: const Text("Download PDF"),
                        ),
                      ],
                      child: _salesManagerAnalysis(),
                    ),
                  ),
                ),

                Visibility(
                  visible: salesPersonData.tsmwiseData.isNotEmpty,
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
                            color: const Color(0xFF6CCC3F),
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
                            await generateSalesPersonAnalysisSOExcel(
                              salesPersonData,
                            );
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            await generateSalesPersonAnalysisSOPDF(
                              salesPersonData,
                            );
                          },
                          child: const Text("Download PDF"),
                        ),
                      ],
                      child: _salesPersonAnalysis(),
                    ),
                  ),
                ),

                Visibility(
                  visible: itemGroupWiseData.productGroupData.isNotEmpty,
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
                            color: const Color(0xFF6CCC3F),
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
                            generateItemGroupWiseAnalysisSOExcel(
                              itemGroupWiseData,
                            );
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            generateItemGroupWiseAnalysisSOPDF(
                              itemGroupWiseData,
                            );
                          },
                          child: const Text('Download PDF'),
                        ),
                      ],
                      child: _itemGroupWiseAnalysis(),
                    ),
                  ),
                ),

                Visibility(
                  visible: itemAnalysisData.productData.isNotEmpty,
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
                            color: const Color(0xFF6CCC3F),
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
                            generateItemAnalysisSOExcel(itemAnalysisData);
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            generateItemAnalysisSOPDF(itemAnalysisData);
                          },
                          child: const Text('Download PDF'),
                        ),
                      ],
                      child: _itemWiseAnalysis(),
                    ),
                  ),
                ),

                Visibility(
                  visible: openSoAgingData.soAgingData.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DashboardCardUI(
                      title: 'Open SO Aging',
                      spacing: 20,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 8,
                            width: 8,
                            color: const Color(0xFF6CCC3F),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Achieved',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                      menuItems: [
                        PopupMenuItem(
                          onTap: () async {
                            generateOpenSOAgingExcel(openSoAgingData);
                          },
                          child: const Text('Download Excel'),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            generateOpenSOAgingPDF(openSoAgingData);
                          },
                          child: const Text('Download PDF'),
                        ),
                      ],
                      child: _openSOAging(),
                    ),
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  void showLoaderDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 15),
              Text("Loading..."),
            ],
          ),
        );
      },
    );
  }

  Widget _monthlyWiseSOAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    if (monthlySalesOrderList.soData.length > 5) {
      chartWidth = screenWidth * 1.4;
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _monthlySOHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(monthlySalesOrderList),
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
                  sideTitles: _bottomTitlesMonthWiseSO,
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
              barGroups: _monthWiseSOChartData(monthlySalesOrderList.soData),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      touchedMonth = monthlySalesOrderList
                          .soData[barTouchResponse.spot!.spot.x.toInt()]
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
                        touchedMonthIndex = touchedMonthIndex == 0
                            ? months.indexOf(touchedMonth.substring(0, 3)) + 1
                            : 0;
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showDrillDownChart = true;
                        loadDataWithFilter(
                          touchedMonthIndex,
                          touchedRegionalManager,
                          touchedSalesManager,
                          touchedSalesRep,
                          touchedCustomer,
                          touchedProductGroup,
                          touchedProduct,
                          touchedAgingCategory,
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
                      '${monthlySalesOrderList.soData[grpIndex].monthName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Achievement : ${(monthlySalesOrderList.soData[grpIndex].salesOrderAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "3 Month Avg. : ${(monthlySalesOrderList.soData[grpIndex].salesOrderTarget / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${((monthlySalesOrderList.soData[grpIndex].salesOrderAmount - monthlySalesOrderList.soData[grpIndex].salesOrderTarget) / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${((monthlySalesOrderList.soData[grpIndex].salesOrderAmount / monthlySalesOrderList.soData[grpIndex].salesOrderTarget) * 100).toStringAsFixed(2)}%",
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

  Widget _customerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = customerAnalysisData.customerData.length;
    if (customerAnalysisData.customerData.length > 5) {
      chartWidth = screenWidth + (30 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _customerHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getCustomerMaxValue(customerAnalysisData),
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
              barGroups: _customerAnalysisChartData(
                customerAnalysisData.customerData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedCustomer = touchedCustomer == ""
                            ? customerAnalysisData
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
                          touchedCustomer,
                          touchedProductGroup,
                          touchedProduct,
                          touchedAgingCategory,
                        );
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
                    width: 2.0,
                    color: Colors.black12,
                    style: BorderStyle.none,
                  ),
                  getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                    return BarTooltipItem(
                      '${customerAnalysisData.customerData[grpIndex].customerName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Achievement : ${(customerAnalysisData.customerData[grpIndex].saleAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "3 Month Avg. : ${(customerAnalysisData.customerData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${((customerAnalysisData.customerData[grpIndex].saleAmount - customerAnalysisData.customerData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${((customerAnalysisData.customerData[grpIndex].saleAmount / customerAnalysisData.customerData[grpIndex].targetAmount == 0 ? customerAnalysisData.customerData[grpIndex].saleAmount : customerAnalysisData.customerData[grpIndex].targetAmount) * 100).ceil().toStringAsFixed(0)}%",
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

  int determineGrpIndex(
    Offset tapPosition,
    List<AsmwiseData> asmwiseData,
    double chartWidth,
  ) {
    double barWidth = chartWidth / asmwiseData.length;
    int index = (tapPosition.dx / barWidth).floor();
    if (index >= 0 && index < asmwiseData.length) {
      return index - 1;
    } else {
      return -1; // Indicating that no bar was tapped
    }
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
    int len = salesManagerData.asmwiseData.length;
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
              maxY: max(1, getAsmMaxValue(salesManagerData)),
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
                  sideTitles: _bottomTitlesManager,
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

              barGroups: _salesManagerAnalysisChartData(
                salesManagerData.asmwiseData,
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
                      index >= salesManagerData.asmwiseData.length) {
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
                          ? salesManagerData.asmwiseData[index].asmName
                          : "";
                      selectedChart = index.toDouble();
                      showDrillDownChart = true;
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
                    final data = salesManagerData.asmwiseData[groupIndex];
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
    int len = salesPersonData.tsmwiseData.length;
    if (salesPersonData.tsmwiseData.length > 5) {
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
              maxY: max(1, getTsmMaxValue(salesPersonData)),
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
                  sideTitles: _bottomTitlesSalesPerson,
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
              barGroups: _salesPersonAnalysisChartData(
                salesPersonData.tsmwiseData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                handleBuiltInTouches: true,
                touchExtraThreshold: const EdgeInsets.all(10),
                touchCallback: (event, response) async {
                  if (response == null || response.spot == null) return;
                  int index = response.spot!.spot.x.toInt();
                  if (index < 0 ||
                      index >= salesPersonData.tsmwiseData.length) {
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
                          ? salesPersonData.tsmwiseData[index].tsmName
                          : "";
                      selectedChart = index.toDouble();
                      showDrillDownChart = true;
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
                      '${salesPersonData.tsmwiseData[groupIndex].tsmName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text:
                              "Achievement : ${(salesPersonData.tsmwiseData[groupIndex].salesAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Target : ${(salesPersonData.tsmwiseData[groupIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${((salesPersonData.tsmwiseData[groupIndex].salesAmount - salesPersonData.tsmwiseData[groupIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${salesPersonData.tsmwiseData[groupIndex].targetAmount == 0 ? "0%" : "${((salesPersonData.tsmwiseData[groupIndex].salesAmount / salesPersonData.tsmwiseData[groupIndex].targetAmount) * 100).toStringAsFixed(0)}%"}",
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

  Widget _itemGroupWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemGroupWiseData.productGroupData.length;
    if (itemGroupWiseData.productGroupData.length > 5) {
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
              maxY: getItemGroupMaxValue(itemGroupWiseData),
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
                  sideTitles: _bottomTitlesItemGroupWise,
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
              barGroups: _itemGroupWiseAnalysisChartData(
                itemGroupWiseData.productGroupData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedProductGroup = touchedProductGroup == ""
                            ? itemGroupWiseData
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
                      '${itemGroupWiseData.productGroupData[grpIndex].productGroupName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Achievement : ${(itemGroupWiseData.productGroupData[grpIndex].salesAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "3 Month Avg. : ${(itemGroupWiseData.productGroupData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${((itemGroupWiseData.productGroupData[grpIndex].salesAmount - itemGroupWiseData.productGroupData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${((itemGroupWiseData.productGroupData[grpIndex].salesAmount / itemGroupWiseData.productGroupData[grpIndex].targetAmount) * 100).ceil().toStringAsFixed(0)}%",
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
    int length = itemAnalysisData.productData.length;
    length > 6
        ? barChartWidth = screenWidth + (35 * length)
        : barChartWidth = screenWidth;

    final amounts = itemAnalysisData.productData
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
                            ? itemAnalysisData
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
                      '${itemAnalysisData.productData[grpIndex].productName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Achievement : ${(itemAnalysisData.productData[grpIndex].salesAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "3 Month Avg. : ${(itemAnalysisData.productData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${((itemAnalysisData.productData[grpIndex].salesAmount - itemAnalysisData.productData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${((itemAnalysisData.productData[grpIndex].salesAmount / itemAnalysisData.productData[grpIndex].targetAmount) * 100).ceil().toStringAsFixed(0)}%",
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
                  sideTitles: _bottomTitlesItem,
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
              barGroups: _itemAnalysisChartData(itemAnalysisData.productData),
            ),
          ),
        ),
      ),
    );
  }

  Widget _openSOAging() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = openSoAgingData.soAgingData.length;
    if (openSoAgingData.soAgingData.length > 5) {
      chartWidth = screenWidth + (30 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _soAgeingHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: max(1, getSoAgeingMaxValue(openSoAgingData)),
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
                  sideTitles: _bottomTitlesOpenSOAging,
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
              barGroups: _openSOAgingChartData(openSoAgingData.soAgingData),
              barTouchData: BarTouchData(
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
                      'Open SO Aging\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "0-30 : ${(((openSoAgingData.soAgingData[0].receivableAmount) / 100000).toStringAsFixed(2))} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "31-60 : ${(((openSoAgingData.soAgingData[1].receivableAmount) / 100000).toStringAsFixed(2))} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "61-90 : ${(((openSoAgingData.soAgingData[2].receivableAmount) / 100000).toStringAsFixed(2))} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "90+ : ${(((openSoAgingData.soAgingData[3].receivableAmount) / 100000).toStringAsFixed(2))} L",
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
}
