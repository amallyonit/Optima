// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, avoid_print, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';
import 'package:optima/pages/dashboardPages/pdf_helper_web.dart';

import 'package:optima/pages/dashboardPages/salesDashboardBI/soAnalysisBI.dart';
import '../../../api_helper.dart';
import '../../../classes/leads.dart';
import '../../../login_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

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

YTDSalesList ytdSalesList = YTDSalesList(ytdData: []);
ItemYTDSalesList ytdItemSalesList = ItemYTDSalesList(ytdData: []);
MonthlySalesList monthlySalesList = MonthlySalesList(monthlyData: []);
int touchedMonthIndex = 0;
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
List<Users> usersListForFilter = [];
List<Users> usersList = [];
List<Users> childUsers = [];
String UserLevel = "0";
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
double LastMonthPercentage = 0;
double CurrentQtrSales = 0;
String CurrentQtrSalesStr = "";
double CurrentQtrTarget = 0;
String CurrentQtrTargetStr = "";
double CurrentQtrPercentage = 0;
double YtdSales = 0;
String YtdSalesStr = "";
double YtdTarget = 0;
String YtdTargetStr = "";
double YtdPercentage = 0;
int CurrentMonthSalesPercentage = 0;
String CurrentMonthSalesPercentageStr = "";
String LastMonthPercentageStr = "";
String CurrentQtrPercentageStr = "";
String YtdPercentageStr = "";
List<Map<String, dynamic>> salesList = [];
List<SalesList> sales = [];
bool noUserList = false;
bool chartDataLoaded = false;
bool YtdSalesBarChartData = false;
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
  List<double> selectedMonthSales = [];
  ScrollController salesPerformancePageController = ScrollController();

  double roundUpToLakhs(double value, double roundValue) {
    return (value / roundValue).ceil() * roundValue.toDouble();
  }

  double roundDownToLakhs(double value, double roundValue) {
    return (value / roundValue).floor() * roundValue.toDouble();
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
    return monthlyData
        .map(
          (sales) => BarChartGroupData(
            x: monthlyData.indexOf(sales),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: sales.salesTarget,
                  show: true,
                  color: const Color(0xFFF49136),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: sales.salesAmount,
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
    double maxValue = 0.0;
    for (var monthlyData in monthlySalesList.monthlyData) {
      maxValue = maxValue > monthlyData.salesAmount
          ? maxValue
          : monthlyData.salesAmount;
      maxValue = maxValue > monthlyData.salesTarget
          ? maxValue
          : monthlyData.salesTarget;
    }
    double divVal = 0;
    if (maxValue >= 10000000) {
      divVal = 10000000;
    } else if (maxValue >= 1000000 && maxValue <= 10000000) {
      divVal = 1000000;
    } else if (maxValue >= 100000 && maxValue <= 1000000) {
      divVal = 50000;
    } else if (maxValue >= 50000 && maxValue <= 100000) {
      divVal = 50000;
    } else {
      divVal = 1000;
    }
    return ((maxValue ~/ divVal) + 1) * divVal;
  }

  double getCustomerStateMaxValue(
    CustomerStateWiseSalesList customerStateWiseSalesList,
  ) {
    double maxValue = 0.0;
    for (var soData in customerStateWiseSalesList.customerStateData) {
      maxValue = maxValue > soData.saleAmount ? maxValue : soData.saleAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    double divVal = 0;
    if (maxValue >= 10000000) {
      divVal = 10000000;
    } else if (maxValue >= 1000000 && maxValue <= 10000000) {
      divVal = 1000000;
    } else if (maxValue >= 100000 && maxValue <= 1000000) {
      divVal = 50000;
    } else if (maxValue >= 50000 && maxValue <= 100000) {
      divVal = 50000;
    } else {
      divVal = 1000;
    }
    return ((maxValue ~/ divVal) + 1) * divVal;
  }

  double getCustomerMaxValue(CustomerWiseSalesList customerAnalysisData) {
    double maxValue = 0.0;
    for (var soData in customerAnalysisData.customerData) {
      maxValue = maxValue > soData.saleAmount ? maxValue : soData.saleAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    double divVal = 0;
    if (maxValue >= 10000000) {
      divVal = 10000000;
    } else if (maxValue >= 1000000 && maxValue <= 10000000) {
      divVal = 1000000;
    } else if (maxValue >= 100000 && maxValue <= 1000000) {
      divVal = 50000;
    } else if (maxValue >= 50000 && maxValue <= 100000) {
      divVal = 50000;
    } else {
      divVal = 1000;
    }
    return ((maxValue ~/ divVal) + 1) * divVal;
  }

  double getRsmMaxValue(RsmwiseSalesList rsmManagerData) {
    double maxValue = 0.0;
    for (var soData in rsmManagerData.rsmwiseData) {
      maxValue = maxValue > soData.salesAmount ? maxValue : soData.salesAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    double divVal = 0;
    if (maxValue >= 10000000) {
      divVal = 10000000;
    } else if (maxValue >= 1000000 && maxValue <= 10000000) {
      divVal = 1000000;
    } else if (maxValue >= 100000 && maxValue <= 1000000) {
      divVal = 50000;
    } else if (maxValue >= 50000 && maxValue <= 100000) {
      divVal = 50000;
    } else {
      divVal = 1000;
    }
    return ((maxValue ~/ divVal) + 1) * divVal;
  }

  double getAsmMaxValue(AsmwiseSalesList salesManagerData) {
    double maxValue = 0.0;
    for (var soData in salesManagerData.asmwiseData) {
      maxValue = maxValue > soData.salesAmount ? maxValue : soData.salesAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    double divVal = 0;
    if (maxValue >= 10000000) {
      divVal = 10000000;
    } else if (maxValue >= 1000000 && maxValue <= 10000000) {
      divVal = 1000000;
    } else if (maxValue >= 100000 && maxValue <= 1000000) {
      divVal = 50000;
    } else if (maxValue >= 50000 && maxValue <= 100000) {
      divVal = 50000;
    } else {
      divVal = 1000;
    }
    return ((maxValue ~/ divVal) + 1) * divVal;
  }

  double getTsmMaxValue(TsmwiseSalesList salesPersonData) {
    double maxValue = 0.0;
    for (var soData in salesPersonData.tsmwiseData) {
      maxValue = maxValue > soData.salesAmount ? maxValue : soData.salesAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    double divVal = 0;
    if (maxValue >= 10000000) {
      divVal = 10000000;
    } else if (maxValue >= 1000000 && maxValue <= 10000000) {
      divVal = 1000000;
    } else if (maxValue >= 100000 && maxValue <= 1000000) {
      divVal = 50000;
    } else if (maxValue >= 50000 && maxValue <= 100000) {
      divVal = 50000;
    } else {
      divVal = 1000;
    }
    return ((maxValue ~/ divVal) + 1) * divVal;
  }

  double getItemGroupMaxValue(ProductGroupwiseSalesList itemGroupWiseData) {
    double maxValue = 0.0;
    for (var soData in itemGroupWiseData.productGroupData) {
      maxValue = maxValue > soData.salesAmount ? maxValue : soData.salesAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    double divVal = 0;
    if (maxValue >= 10000000) {
      divVal = 10000000;
    } else if (maxValue >= 1000000 && maxValue <= 10000000) {
      divVal = 1000000;
    } else if (maxValue >= 100000 && maxValue <= 1000000) {
      divVal = 50000;
    } else if (maxValue >= 50000 && maxValue <= 100000) {
      divVal = 50000;
    } else {
      divVal = 1000;
    }
    return ((maxValue ~/ divVal) + 1) * divVal;
  }

  double getItemMaxValue(ProductwiseSalesList itemAnalysisData) {
    double maxValue = 0.0;
    for (var soData in itemAnalysisData.productData) {
      maxValue = maxValue > soData.salesAmount ? maxValue : soData.salesAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    double divVal = 0;
    if (maxValue >= 10000000) {
      divVal = 10000000;
    } else if (maxValue >= 1000000 && maxValue <= 10000000) {
      divVal = 1000000;
    } else if (maxValue >= 100000 && maxValue <= 1000000) {
      divVal = 50000;
    } else if (maxValue >= 50000 && maxValue <= 100000) {
      divVal = 50000;
    } else {
      divVal = 1000;
    }
    return ((maxValue ~/ divVal) + 1) * divVal;
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
            final snackBar = SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(
                responseJson["Error"].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          }
        }
      } else {
        const snackBar = SnackBar(content: Text('User list not found.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
            final snackBar = SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(
                responseJson["Error"].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
        const snackBar = SnackBar(content: Text('User list not found.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text('Error: $e'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
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
    // treeController = TreeController<MyNode>(
    //   roots: nodes,
    //   childrenProvider: (MyNode node) => node.children,
    // );

    return nodes;
  }

  Future<void> _loadSalesTarget(String UserName, String UserLevel) async {
    final body = {
      "Index": 0,
      "Limit": 0,
      "sapToken": DataManager.readSapToken(),
    };
    const apiUrl = '${ApiHelper.baseUrl}BicxoSalesTargetList';
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      // HttpHeaders.authorizationHeader: 'Bearer    ${DataManager.readSapToken()}'
    };
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
            final snackBar = SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(
                responseJson["Error"].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        const snackBar = SnackBar(
          content: Text('Sales target details not found.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      const snackBar = SnackBar(
        content: Text('SAP Server down, Please try again after some time.'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadSales(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<SalesList> salesList = [];
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
        const apiUrl = '${ApiHelper.baseUrl}Crm_SalesList';
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
            List<SalesList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => SalesList.fromJson(item))
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
        context.read<SalesListSalesAnalysisProvider>().updateSalesList(
          salesList,
        );
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          sales = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          sales = salesList
              .where((element) => element.regionalManager == UserName)
              .toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          sales = salesList
              .where((element) => menuNames.contains(element.salesManager))
              .toList();
        } else {
          sales = salesList
              .where((element) => element.salesRep == UserName)
              .toList();
        }
      });

      double sum = 0;
      var currentMonthSales = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;

        return invoiceDate.isAtLeast(currentMonthFromDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      double salesAmt = 0;
      for (var target in currentMonthSales.toList()) {
        // if (target.invoiceType != "Sales Return") {
        //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
        // } else {
        //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
        // }
        salesAmt = double.tryParse(target.rowTotal) ?? 0;
        sum += salesAmt;
      }

      CurrentMonthSales = sum;
      CurrentMonthSalesStr =
          "${(CurrentMonthSales / 100000).toStringAsFixed(2)} L";
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

      var lastMonthSales = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;

        return invoiceDate.isAtLeast(lastMonthFromDate!) &&
            invoiceDate.isAtMost(lastMonthToDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in lastMonthSales.toList()) {
        // if (target.invoiceType != "Sales Return") {
        //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
        // } else {
        //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
        // }
        salesAmt = double.tryParse(target.rowTotal) ?? 0;
        sum += salesAmt;
      }

      LastMonthSales = sum;
      LastMonthSalesStr = "${(LastMonthSales / 100000).toStringAsFixed(2)} L";
      if (LastMonthSales == 0) {
        LastMonthPercentage = 0;
      } else {
        LastMonthPercentage =
            (double.tryParse(
                      ((LastMonthSales / LastMonthTarget) * 100)
                          .toStringAsFixed(2),
                    )?.ceil() ??
                    0)
                .toDouble();
      }
      LastMonthPercentageStr = "${LastMonthPercentage.toString()} %";
      if (LastMonthPercentage > 100) {
        LastMonthPercentage = 100;
      }

      var curQtrSales = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;
        return invoiceDate.isAtLeast(currentQuarterFromDate!) &&
            invoiceDate.isAtMost(currentQuarterToDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in curQtrSales.toList()) {
        // if (target.invoiceType != "Sales Return") {
        //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
        // } else {
        //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
        // }
        salesAmt = double.tryParse(target.rowTotal) ?? 0;
        sum += salesAmt;
      }

      CurrentQtrSales = sum;
      CurrentQtrSalesStr = "${(CurrentQtrSales / 100000).toStringAsFixed(2)} L";
      if (CurrentQtrSales == 0) {
        CurrentQtrPercentage = 0;
      } else {
        CurrentQtrPercentage =
            (double.tryParse(
                      ((CurrentQtrSales / CurrentQtrTarget) * 100)
                          .toStringAsFixed(2),
                    )?.ceil() ??
                    0)
                .toDouble();
      }
      CurrentQtrPercentageStr = "${CurrentQtrPercentage.toString()} %";
      if (CurrentQtrPercentage > 100) {
        CurrentQtrPercentage = 100;
      }

      var ytdSales = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;
        return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in ytdSales.toList()) {
        // if (target.invoiceType != "Sales Return") {
        //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
        // } else {
        //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
        // }
        salesAmt = double.tryParse(target.rowTotal) ?? 0;
        sum += salesAmt;
      }

      YtdSales = sum;
      YtdSalesStr = "${(YtdSales / 100000).toStringAsFixed(2)} L";
      if (YtdSales == 0) {
        YtdPercentage = 0;
      } else {
        YtdPercentage =
            (double.tryParse(
                      ((YtdSales / YtdTarget) * 100).toStringAsFixed(2),
                    )?.ceil() ??
                    0)
                .toDouble();
      }
      YtdPercentageStr = "${YtdPercentage.toString()} %";

      if (YtdPercentage > 100) {
        YtdPercentage = 100;
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
            // if (target.invoiceType != "Sales Return") {
            //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
            // } else {
            //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
            // }
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
            // if (target.invoiceType != "Sales Return") {
            //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
            // } else {
            //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
            // }
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
            // if (target.invoiceType != "Sales Return") {
            //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
            // } else {
            //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
            // }
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
            // if (target.invoiceType != "Sales Return") {
            //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
            // } else {
            //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
            // }
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

  List<SalesList> filterSalesListOld(
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
    print("OLD FILTER METHOD CALLED");
    bool regionalManagerCondition = true;
    bool salesManagerCondition = true;
    List<SalesList> filteredSalesList = [];
    for (var sale in salesList) {
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

      if (!regionalManagerCondition || !salesManagerCondition) {
        continue; // Skip this sale if either regionalManager or salesManager condition fails
      }

      if ((salesRep == null || salesRep.isEmpty || sale.salesRep == salesRep) &&
          (stateName == null ||
              stateName.isEmpty ||
              sale.customerState == stateName) &&
          (customerCode == null ||
              customerCode.isEmpty ||
              sale.customerCode == customerCode) &&
          (productCode == null ||
              productCode.isEmpty ||
              sale.code == productCode) &&
          (productGroupCode == null ||
              productGroupCode.isEmpty ||
              sale.itemSubGroup == productGroupCode)) {
        filteredSalesList.add(sale);
      }
    }
    return filteredSalesList;
  }

  List<SalesTargetList> filterSalesTargetList(
    List<SalesTargetList> salesTargetList,
    List<Users> userNames, {
    String? regionalManager,
    String? salesManager,
    String? salesRep,
  }) {
    bool regionalManagerCondition = true;
    bool salesManagerCondition = true;
    List<SalesTargetList> filteredSalesTargetList = [];

    for (var target in salesTargetList) {
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
            childMenuNames.contains(target.salesManager);
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
            salesManagerMenuId != -1 &&
            childMenuNames.contains(target.salesRep);
      }
      if (!regionalManagerCondition || !salesManagerCondition) {
        continue; // Skip this sale if either regionalManager or salesManager condition fails
      }
      filteredSalesTargetList.add(target);
    }
    return filteredSalesTargetList;
  }

  Future<void> _loadMonthlySalesBarChartData() async {
    List<MonthlySalesData> monthlyDataList = [];
    prevYearMonthList = PrevYearMonthList(prevYearMonthData: []);
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    for (int i = 4; i <= 15; i++) {
      String monthName = getMonthName(i);
      double monthlyTarget = 0.00;
      double monthlySales = 0.00;
      for (var target in salesTarget.where(
        (element) => element.financialYear == financialYear,
      )) {
        monthlyTarget +=
            double.tryParse(target.getTargetForMonth(monthName)) ?? 0;
      }
      var monthlySalesList = const Iterable.empty();
      if (i >= 4 && i <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(i);
        monthlySalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear + 1, i - 12, 1);
        endDate = DateTime(currentYear + 1, (i - 12) + 1, 0);
        monthlySalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
      double salesAmt = 0;
      for (var target in monthlySalesList.toList()) {
        // if (target.invoiceType != "Sales Return") {
        //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
        // } else {
        //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
        // }
        salesAmt = double.tryParse(target.rowTotal) ?? 0;
        monthlySales += salesAmt;
      }
      monthlyDataList.add(
        MonthlySalesData(
          monthName: monthName,
          salesAmount: monthlySales,
          salesTarget: monthlyTarget,
        ),
      );
      monthlySales = 0;
      monthlyTarget = 0;
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
    LoadDates();
    LoadAllQuarterFromToDates();
    List<MonthlySalesData> monthlyDataList = [];
    List<PrevYearMonthData> prevYearMonthDataList = [];
    prevYearMonthList = PrevYearMonthList(prevYearMonthData: []);

    String monthName = "";
    double monthlyTarget = 0.00;
    double monthlySales = 0.00;
    if (piechartIndex == 1) {
      monthName = getMonthName(lastMonthFromDate!.month);
      if (currentDate!.month == 4) {
        for (var target in salesTarget.where(
          (element) => element.financialYear == prevFinancialYear,
        )) {
          monthlyTarget +=
              double.tryParse(
                target.getTargetForMonth(
                  getMonthName(lastMonthFromDate!.month),
                ),
              ) ??
              0;
          prevYearMonthDataList.add(PrevYearMonthData(monthName: monthName));
        }
      } else {
        for (var target in salesTarget.where(
          (element) => element.financialYear == financialYear,
        )) {
          monthlyTarget +=
              double.tryParse(
                target.getTargetForMonth(
                  getMonthName(lastMonthFromDate!.month),
                ),
              ) ??
              0;
        }
      }
      var lastMonthSales = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;
        return invoiceDate.isAtLeast(lastMonthFromDate!) &&
            invoiceDate.isAtMost(lastMonthToDate!);
      });
      double salesAmt = 0;
      for (var target in lastMonthSales.toList()) {
        // if (target.invoiceType != "Sales Return") {
        //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
        // } else {
        //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
        // }
        salesAmt = double.tryParse(target.rowTotal) ?? 0;
        monthlySales += salesAmt;
      }

      monthlyDataList.add(
        MonthlySalesData(
          monthName: monthName,
          salesAmount: monthlySales,
          salesTarget: monthlyTarget,
        ),
      );
      prevYearMonthList = PrevYearMonthList(
        prevYearMonthData: prevYearMonthDataList,
      );
    } else {
      DateTime? qrtFromDate = currentQuarterFromDate;
      DateTime? qrtToDate = addMonth(
        qrtFromDate!,
        1,
      ).add(const Duration(days: -1));
      for (int i = 1; i <= 3; i++) {
        monthName = getMonthName(qrtFromDate!.month);
        for (var target in salesTarget.where(
          (element) => element.financialYear == financialYear,
        )) {
          monthlyTarget +=
              double.tryParse(
                target.getTargetForMonth(getMonthName(qrtFromDate.month)),
              ) ??
              0;
        }

        var curQtrSales = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(qrtFromDate!) &&
              invoiceDate.isAtMost(qrtToDate!);
        });

        double salesAmt = 0;
        for (var target in curQtrSales.toList()) {
          // if (target.invoiceType != "Sales Return") {
          //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
          // } else {
          //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
          // }
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          monthlySales += salesAmt;
        }

        monthlyDataList.add(
          MonthlySalesData(
            monthName: monthName,
            salesAmount: monthlySales,
            salesTarget: monthlyTarget,
          ),
        );
        monthlySales = 0;
        monthlyTarget = 0;
        prevYearMonthList = PrevYearMonthList(
          prevYearMonthData: prevYearMonthDataList,
        );
        qrtFromDate = addOneMonth(qrtFromDate);
        qrtToDate = addMonth(qrtFromDate, 1).add(const Duration(days: -1));
      }
    }
    monthlySalesList = MonthlySalesList(monthlyData: monthlyDataList);
  }

  Future<void> _loadMonthlyProductwiseSalesBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String stateName,
    String customerCode,
    String productGroupCode,
    String productCode,
  ) async {
    List<ProductwiseData> productwiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String itemCode = "";
    String itemName = "";
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

    var curMthSalesTarget = sales.where((target) {
      DateTime invoiceDate = target.invoiceDate;
      return invoiceDate.isAtLeast(prevThreethFromDate) &&
          invoiceDate.isAtMost(prevThreeMthToDate);
    });

    var productSalesList = const Iterable.empty();
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      productSalesList = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        productSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        productSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }

    productSalesList = filterSalesListOld(
      productSalesList.cast<SalesList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );
    curMthSalesTarget = filterSalesListOld(
      curMthSalesTarget.cast<SalesList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    Set<String> processedProductCodes = {};
    for (var product in productSalesList.toList()) {
      if (!processedProductCodes.contains(product.code)) {
        itemCode = product.code;
        itemName = product.description;
        for (var target in productSalesList.where(
          (prdelement) => prdelement.code == itemCode,
        )) {
          double salesAmt = 0;
          // if (target.invoiceType != "Sales Return") {
          //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
          // } else {
          //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
          // }
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productSales += salesAmt;
        }
        for (var target in curMthSalesTarget.where(
          (element) => element.code == itemCode,
        )) {
          double salesAmt = 0;
          // if (target.invoiceType != "Sales Return") {
          //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
          // } else {
          //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
          // }
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productTarget += salesAmt;
        }

        productwiseDataList.add(
          ProductwiseData(
            productCode: itemCode,
            productName: itemName,
            salesAmount: productSales,
            targetAmount: productTarget / 3,
          ),
        );
        processedProductCodes.add(product.code);
      }
      productSales = 0;
      productTarget = 0;
      itemCode = "";
      itemName = "";
    }
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    productwiseSalesList = ProductwiseSalesList(
      productData: productwiseDataList,
    );
  }

  Future<void> _loadMonthlyProductGroupwiseSalesBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String stateName,
    String customerCode,
    String productGroupCode,
    String productCode,
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

    var curMthSalesTarget = sales.where((target) {
      DateTime invoiceDate = target.invoiceDate;
      return invoiceDate.isAtLeast(prevThreethFromDate) &&
          invoiceDate.isAtMost(prevThreeMthToDate);
    });

    var productSalesList = const Iterable.empty();
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      productSalesList = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        productSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        productSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }

    productSalesList = filterSalesListOld(
      productSalesList.cast<SalesList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );
    curMthSalesTarget = filterSalesListOld(
      curMthSalesTarget.cast<SalesList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
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
          double salesAmt = 0;
          // if (target.invoiceType != "Sales Return") {
          //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
          // } else {
          //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
          // }
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productSales += salesAmt;
        }
        for (var target in curMthSalesTarget.where(
          (element) => element.itemSubGroup == productGroupName,
        )) {
          double salesAmt = 0;
          // if (target.invoiceType != "Sales Return") {
          //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
          // } else {
          //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
          // }
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productTarget += salesAmt;
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
    productGroupwiseSalesList = ProductGroupwiseSalesList(
      productGroupData: productGroupwiseDataList,
    );
  }

  Future<void> _loadMonthlyCustomerWiseSalesBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String stateName,
    String customerCode,
    String productGroupCode,
    String productCode,
  ) async {
    List<CustomerWiseData> customerWiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String custCode = "";
    String custName = "";
    double customerSales = 0.00;
    double customerTarget = 0.00;
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

    var curMthSalesTarget = sales.where((target) {
      DateTime invoiceDate = target.invoiceDate;
      return invoiceDate.isAtLeast(prevThreethFromDate) &&
          invoiceDate.isAtMost(prevThreeMthToDate);
    });

    var customerSalesList = const Iterable.empty();

    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      customerSalesList = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        customerSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        customerSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }
    customerSalesList = filterSalesListOld(
      customerSalesList.cast<SalesList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );
    curMthSalesTarget = filterSalesListOld(
      curMthSalesTarget.cast<SalesList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );
    Set<String> processedCustomerCodes = {};
    for (var customer in customerSalesList.toList()) {
      if (!processedCustomerCodes.contains(customer.customerCode)) {
        custCode = customer.customerCode;
        custName = customer.customerName;
        for (var sales in customerSalesList.where(
          (saleelement) => saleelement.customerCode == custCode,
        )) {
          double salesAmt = 0;
          // if (sales.invoiceType != "Sales Return") {
          //   salesAmt = double.tryParse(sales.rowTotal) ?? 0;
          // } else {
          //   salesAmt = (double.tryParse(sales.rowTotal) ?? 0) * -1;
          // }
          salesAmt = double.tryParse(sales.rowTotal) ?? 0;
          customerSales += salesAmt;
        }

        for (var target in curMthSalesTarget.where(
          (element) => element.customerCode == custCode,
        )) {
          double salesAmt = 0;
          // if (target.invoiceType != "Sales Return") {
          //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
          // } else {
          //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
          // }
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          customerTarget += salesAmt;
        }

        customerWiseDataList.add(
          CustomerWiseData(
            customerCode: custCode,
            customerName: custName,
            saleAmount: customerSales,
            targetAmount: customerTarget / 3,
          ),
        );
        processedCustomerCodes.add(custCode);
      }
      customerSales = 0;
      customerTarget = 0;
      custCode = "";
      custName = "";
    }

    customerWiseDataList.sort((a, b) => b.saleAmount.compareTo(a.saleAmount));
    customerWiseSalesList = CustomerWiseSalesList(
      customerData: customerWiseDataList,
    );
  }

  Future<void> _loadMonthlyCustomerStateWiseSalesBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String stateName,
    String customerCode,
    String productGroupCode,
    String productCode,
  ) async {
    List<CustomerStateWiseData> customerStateDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String state = "";
    double customerSales = 0.00;
    double customerTarget = 0.00;

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

    var curMthSalesTarget = sales.where((target) {
      DateTime invoiceDate = target.invoiceDate;
      return invoiceDate.isAtLeast(prevThreethFromDate) &&
          invoiceDate.isAtMost(prevThreeMthToDate);
    });

    var customerSalesList = const Iterable.empty();
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      customerSalesList = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        customerSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        customerSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }
    customerSalesList = filterSalesListOld(
      customerSalesList.cast<SalesList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );
    curMthSalesTarget = filterSalesListOld(
      curMthSalesTarget.cast<SalesList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );
    Set<String> processedCustomerStates = {};
    for (var customer in customerSalesList.toList()) {
      if (!processedCustomerStates.contains(customer.customerState)) {
        state = customer.customerState;
        for (var sales in customerSalesList.where(
          (element) => element.customerState == state,
        )) {
          double salesAmt = 0;
          // if (sales.invoiceType != "Sales Return") {
          //   salesAmt = double.tryParse(sales.rowTotal) ?? 0;
          // } else {
          //   salesAmt = (double.tryParse(sales.rowTotal) ?? 0) * -1;
          // }
          salesAmt = double.tryParse(sales.rowTotal) ?? 0;
          customerSales += salesAmt;
        }
        for (var target in curMthSalesTarget.where(
          (element) => element.customerState == state,
        )) {
          double salesAmt = 0;
          // if (target.invoiceType != "Sales Return") {
          //   salesAmt = double.tryParse(target.rowTotal) ?? 0;
          // } else {
          //   salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
          // }
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          customerTarget += salesAmt;
        }
        customerStateDataList.add(
          CustomerStateWiseData(
            stateName: state,
            saleAmount: customerSales,
            targetAmount: customerTarget / 3,
          ),
        );
        processedCustomerStates.add(state);
      }
      customerSales = 0;
      customerTarget = 0;
      state = "";
    }
    customerStateDataList.sort((a, b) => b.saleAmount.compareTo(a.saleAmount));
    customerStateWiseSalesList = CustomerStateWiseSalesList(
      customerStateData: customerStateDataList,
    );
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
        total = calculateTotalForMonth(month, repList); //Current month data
      }
    }
    return total;
  }

  Future<void> _loadTSMSalesBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String stateName,
    String customerCode,
    String productGroupCode,
    String productCode,
  ) async {
    List<TsmwiseData> tsmwiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String tsmName = "";
    double salesAmount = 0.00;
    double targetAmount = 0.00;

    var tsmSalesList = const Iterable.empty();
    var tsmSalesTargetList = const Iterable.empty();
    var tmpTsmSalesTargetList = const Iterable.empty();
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      tsmSalesList = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        tsmSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);
        tsmSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }
    List<String> monthsToInclude = [];
    int currentMonth = DateTime.now().month;
    if (currentMonth == 1) {
      monthsToInclude = [
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
      ];
      if (monthIndex != 0) {
        ['jan', 'feb', 'mar'].sublist(monthIndex - 1, monthIndex);
      }
    }
    if (currentMonth == 2) {
      monthsToInclude = [
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
      ];
      if (monthIndex != 0) {
        ['jan', 'feb', 'mar'].sublist(monthIndex - 1, monthIndex);
      }
    }
    if (currentMonth == 3) {
      monthsToInclude = [
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
      if (monthIndex != 0) {
        ['jan', 'feb', 'mar'].sublist(monthIndex - 1, monthIndex);
      }
    } else if (currentMonth >= 4 && currentMonth <= 12) {
      List<String> allMonths = [
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
      int monthsCount = 0;
      if (monthIndex == 0) {
        monthsCount = currentMonth - 3;
        monthsToInclude = allMonths.sublist(0, monthsCount);
      } else {
        monthsToInclude = allMonths.sublist(monthIndex - 4, monthIndex - 3);
      }
    }

    tsmSalesTargetList = salesTarget.map((element) {
      Map<String, dynamic> filteredMap = {
        "financialYear": element.financialYear,
        "salesRepCode": element.salesRepCode,
        "salesRep": element.salesRep,
        "salesManager": element.salesManager,
        "regionalManager": element.regionalManager,
      };

      for (var month in monthsToInclude) {
        switch (month) {
          case 'april':
            filteredMap[month] = element.april;
            break;
          case 'may':
            filteredMap[month] = element.may;
            break;
          case 'june':
            filteredMap[month] = element.june;
            break;
          case 'july':
            filteredMap[month] = element.july;
            break;
          case 'aug':
            filteredMap[month] = element.aug;
            break;
          case 'sep':
            filteredMap[month] = element.sep;
            break;
          case 'oct':
            filteredMap[month] = element.oct;
            break;
          case 'nov':
            filteredMap[month] = element.nov;
            break;
          case 'dec':
            filteredMap[month] = element.dec;
            break;
          case 'jan':
            filteredMap[month] = element.jan;
            break;
          case 'feb':
            filteredMap[month] = element.feb;
            break;
          case 'mar':
            filteredMap[month] = element.mar;
            break;
        }
      }
      return filteredMap;
    }).toList();
    tmpTsmSalesTargetList = tsmSalesTargetList;
    List<SalesList> lstSales = tsmSalesList.cast<SalesList>().toList();
    tsmSalesList = filterSalesListOld(
      lstSales,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    List<SalesTargetList> lstSalesTrgt = tsmSalesTargetList
        .map(
          (dynamic item) =>
              SalesTargetList.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    tsmSalesTargetList = filterSalesTargetList(
      lstSalesTrgt,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
    );

    Set<String> processedTsmNames = {};
    List<AsmMenu> asmMenuNames = [];
    List<String> tsmNames = [];

    if (regionalManager == "" && salesManager == "" && salesRep == "") {
      asmMenuNames = usersList
          .where((element) => element.userLevel == 2)
          .map((user) => AsmMenu(user.menuName, user.menuId))
          .toList();
    } else {
      int? managerMenuId = 0;
      if (salesRep != "") {
        managerMenuId = usersList
            .firstWhere(
              (element) => element.menuName == salesRep,
              orElse: () => Users(
                menuId: -1,
                menuName: '',
                subMenuId: -1,
                parentMenuId: -1,
                userLevel: -1,
              ),
            )
            .parentMenuId;
      } else if (salesManager != "") {
        managerMenuId = usersList
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
      } else if (regionalManager != "") {
        managerMenuId = usersList
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
      }
      if (managerMenuId != -1) {
        if (regionalManager != "" && salesManager == "") {
          asmMenuNames = usersList
              .where((element) => element.parentMenuId == managerMenuId)
              .map((user) => AsmMenu(user.menuName, user.menuId))
              .toList();
        } else {
          asmMenuNames = usersList
              .where((element) => element.menuId == managerMenuId)
              .map((user) => AsmMenu(user.menuName, user.menuId))
              .toList();
        }
      }
    }
    for (var asmMenu in asmMenuNames) {
      if (salesRep == "") {
        tsmNames = usersList
            .where((element) => element.parentMenuId == asmMenu.menuId)
            .map((user) => user.menuName)
            .toList();
      } else {
        tsmNames = usersList
            .where((element) => element.menuName == salesRep)
            .map((user) => user.menuName)
            .toList();
      }
      for (var name in tsmNames) {
        if (!processedTsmNames.contains(name)) {
          tsmName = name;
          for (var sales in tsmSalesList.where(
            (tsmelement) => tsmelement.salesRep == tsmName,
          )) {
            double sum = 0.0;
            // if (sales.invoiceType != "Sales Return") {
            //   sum = double.tryParse(sales.rowTotal) ?? 0;
            // } else {
            //   sum = (double.tryParse(sales.rowTotal) ?? 0) * -1;
            // }
            sum = double.tryParse(sales.rowTotal) ?? 0;
            salesAmount += sum;
          }
          targetAmount = calculateTotalForRep(
            tsmName,
            "1",
            tmpTsmSalesTargetList,
          );
          if (salesAmount + targetAmount > 0) {
            tsmwiseDataList.add(
              TsmwiseData(
                tsmName: tsmName,
                salesAmount: salesAmount,
                targetAmount: targetAmount,
              ),
            );
          }
          processedTsmNames.add(tsmName);
        }
        targetAmount = 0;
        salesAmount = 0;
        tsmName = "";
      }
    }
    tsmwiseDataList.sort((a, b) => a.salesAmount.compareTo(b.salesAmount));
    tsmwiseSalesList = TsmwiseSalesList(tsmwiseData: tsmwiseDataList);
  }

  Future<void> _loadASMSalesBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String stateName,
    String customerCode,
    String productGroupCode,
    String productCode,
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
    var tmpAsmSalesTargetList = const Iterable.empty();

    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      asmSalesList = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        asmSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);
        asmSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }
    List<String> monthsToInclude = [];
    int currentMonth = DateTime.now().month;
    if (currentMonth == 1) {
      monthsToInclude = [
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
      ];
      if (monthIndex != 0) {
        ['jan', 'feb', 'mar'].sublist(monthIndex - 1, monthIndex);
      }
    }
    if (currentMonth == 2) {
      monthsToInclude = [
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
      ];
      if (monthIndex != 0) {
        ['jan', 'feb', 'mar'].sublist(monthIndex - 1, monthIndex);
      }
    }
    if (currentMonth == 3) {
      monthsToInclude = [
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
      if (monthIndex != 0) {
        ['jan', 'feb', 'mar'].sublist(monthIndex - 1, monthIndex);
      }
    } else if (currentMonth >= 4 && currentMonth <= 12) {
      List<String> allMonths = [
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
      int monthsCount = 0;
      if (monthIndex == 0) {
        monthsCount = currentMonth - 3;
        monthsToInclude = allMonths.sublist(0, monthsCount);
      } else {
        monthsToInclude = allMonths.sublist(monthIndex - 4, monthIndex - 3);
      }
    }
    // int menuId = 0;
    List<String> menuNames = usersList
        .where((element) => element.userLevel == 2)
        .map((user) => user.menuName)
        .toList();
    if (regionalManager == "" && salesManager == "") {
      asmSalesTargetList = salesTarget.where((target) {
        return menuNames.contains(target.salesManager);
      });
    } else {
      asmSalesTargetList = salesTarget;
    }
    asmSalesTargetList = asmSalesTargetList.map((element) {
      Map<String, dynamic> filteredMap = {
        "financialYear": element.financialYear,
        "salesRepCode": element.salesRepCode,
        "salesRep": element.salesRep,
        "salesManager": element.salesManager,
        "regionalManager": element.regionalManager,
      };

      for (var month in monthsToInclude) {
        switch (month) {
          case 'april':
            filteredMap[month] = element.april;
            break;
          case 'may':
            filteredMap[month] = element.may;
            break;
          case 'june':
            filteredMap[month] = element.june;
            break;
          case 'july':
            filteredMap[month] = element.july;
            break;
          case 'aug':
            filteredMap[month] = element.aug;
            break;
          case 'sep':
            filteredMap[month] = element.sep;
            break;
          case 'oct':
            filteredMap[month] = element.oct;
            break;
          case 'nov':
            filteredMap[month] = element.nov;
            break;
          case 'dec':
            filteredMap[month] = element.dec;
            break;
          case 'jan':
            filteredMap[month] = element.jan;
            break;
          case 'feb':
            filteredMap[month] = element.feb;
            break;
          case 'mar':
            filteredMap[month] = element.mar;
            break;
        }
      }
      return filteredMap;
    }).toList();

    tmpAsmSalesTargetList = asmSalesTargetList;

    List<SalesList> lstSales = asmSalesList.cast<SalesList>().toList();
    asmSalesList = filterSalesListOld(
      lstSales,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    List<SalesTargetList> lstSalesTrgt = asmSalesTargetList
        .map(
          (dynamic item) =>
              SalesTargetList.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    asmSalesTargetList = filterSalesTargetList(
      lstSalesTrgt,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
    );

    List<String> tsmNames = [];
    List<AsmMenu> asmMenuNames = [];
    if (regionalManager == "" && salesManager == "" && salesRep == "") {
      asmMenuNames = usersList
          .where((element) => element.userLevel == 2)
          .map((user) => AsmMenu(user.menuName, user.menuId))
          .toList();
    } else {
      int? managerMenuId = 0;
      if (salesRep != "") {
        managerMenuId = usersList
            .firstWhere(
              (element) => element.menuName == salesRep,
              orElse: () => Users(
                menuId: -1,
                menuName: '',
                subMenuId: -1,
                parentMenuId: -1,
                userLevel: -1,
              ),
            )
            .parentMenuId;
      } else if (salesManager != "") {
        managerMenuId = usersList
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
      } else if (regionalManager != "") {
        managerMenuId = usersList
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
      }
      if (managerMenuId != -1) {
        if (regionalManager != "" && salesManager == "") {
          asmMenuNames = usersList
              .where((element) => element.parentMenuId == managerMenuId)
              .map((user) => AsmMenu(user.menuName, user.menuId))
              .toList();
        } else {
          asmMenuNames = usersList
              .where((element) => element.menuId == managerMenuId)
              .map((user) => AsmMenu(user.menuName, user.menuId))
              .toList();
        }
      }
    }
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
        double sum = 0.0;
        // if (sales.invoiceType != "Sales Return") {
        //   sum = double.tryParse(sales.rowTotal) ?? 0;
        // } else {
        //   sum = (double.tryParse(sales.rowTotal) ?? 0) * -1;
        // }
        sum = double.tryParse(sales.rowTotal) ?? 0;
        salesAmount += sum;
      }
      for (var name in tsmNames) {
        targetAmount += calculateTotalForRep(name, "1", tmpAsmSalesTargetList);
      }
      if (salesAmount + targetAmount > 0) {
        asmwiseDataList.add(
          AsmwiseData(
            asmName: asmName,
            salesAmount: salesAmount,
            targetAmount: targetAmount,
          ),
        );
      }
      asmName = "";
      targetAmount = 0;
      salesAmount = 0;
    }

    asmwiseDataList.sort((a, b) => a.salesAmount.compareTo(b.salesAmount));
    asmwiseSalesList = AsmwiseSalesList(asmwiseData: asmwiseDataList);
  }

  Future<void> _loadRSMSalesBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String stateName,
    String customerCode,
    String productGroupCode,
    String productCode,
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
    var tmpRsmSalesTargetList = const Iterable.empty();

    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      rsmSalesList = sales.where((target) {
        DateTime invoiceDate = target.invoiceDate;
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
        rsmSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);
        rsmSalesList = sales.where((target) {
          DateTime invoiceDate = target.invoiceDate;
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
    }
    List<String> monthsToInclude = [];
    int currentMonth = DateTime.now().month;
    if (currentMonth == 1) {
      monthsToInclude = [
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
      ];
      if (monthIndex != 0) {
        ['jan', 'feb', 'mar'].sublist(monthIndex - 1, monthIndex);
      }
    }
    if (currentMonth == 2) {
      monthsToInclude = [
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
      ];
      if (monthIndex != 0) {
        ['jan', 'feb', 'mar'].sublist(monthIndex - 1, monthIndex);
      }
    }
    if (currentMonth == 3) {
      monthsToInclude = [
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
      if (monthIndex != 0) {
        ['jan', 'feb', 'mar'].sublist(monthIndex - 1, monthIndex);
      }
    } else if (currentMonth >= 4 && currentMonth <= 12) {
      List<String> allMonths = [
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
      int monthsCount = 0;
      if (monthIndex == 0) {
        monthsCount = currentMonth - 3;
        monthsToInclude = allMonths.sublist(0, monthsCount);
      } else {
        monthsToInclude = allMonths.sublist(monthIndex - 4, monthIndex - 3);
      }
    }

    rsmSalesTargetList = salesTarget.map((element) {
      Map<String, dynamic> filteredMap = {
        "financialYear": element.financialYear,
        "salesRepCode": element.salesRepCode,
        "salesRep": element.salesRep,
        "salesManager": element.salesManager,
        "regionalManager": element.regionalManager,
      };

      for (var month in monthsToInclude) {
        switch (month) {
          case 'april':
            filteredMap[month] = element.april;
            break;
          case 'may':
            filteredMap[month] = element.may;
            break;
          case 'june':
            filteredMap[month] = element.june;
            break;
          case 'july':
            filteredMap[month] = element.july;
            break;
          case 'aug':
            filteredMap[month] = element.aug;
            break;
          case 'sep':
            filteredMap[month] = element.sep;
            break;
          case 'oct':
            filteredMap[month] = element.oct;
            break;
          case 'nov':
            filteredMap[month] = element.nov;
            break;
          case 'dec':
            filteredMap[month] = element.dec;
            break;
          case 'jan':
            filteredMap[month] = element.jan;
            break;
          case 'feb':
            filteredMap[month] = element.feb;
            break;
          case 'mar':
            filteredMap[month] = element.mar;
            break;
        }
      }
      return filteredMap;
    }).toList();

    tmpRsmSalesTargetList = rsmSalesTargetList;
    List<SalesList> lstSales = rsmSalesList.cast<SalesList>().toList();
    rsmSalesList = filterSalesListOld(
      lstSales,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      stateName: stateName,
      productCode: productCode,
      productGroupCode: productGroupCode,
      customerCode: customerCode,
    );

    List<SalesTargetList> lstSalesTrgt = rsmSalesTargetList
        .map(
          (dynamic item) =>
              SalesTargetList.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    rsmSalesTargetList = filterSalesTargetList(
      lstSalesTrgt,
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
    );

    Set<String> processedRsmNames = {};
    List<AsmMenu> asmNames = [];
    List<String> tsmNames = [];
    List<RsmMenu> rsmMenuNames = [];
    if (int.tryParse(UserLevel)! > 3) {
      if (regionalManager == "") {
        rsmMenuNames = usersList
            .where((element) => element.userLevel == 3)
            .map((user) => RsmMenu(user.menuName, user.menuId))
            .toList();
      } else {
        rsmMenuNames = usersList
            .where((element) => element.menuName == regionalManager)
            .map((user) => RsmMenu(user.menuName, user.menuId))
            .toList();
      }
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
              double sum = 0.0;
              // if (sales.invoiceType != "Sales Return") {
              //   sum = double.tryParse(sales.rowTotal) ?? 0;
              // } else {
              //   sum = (double.tryParse(sales.rowTotal) ?? 0) * -1;
              // }
              sum = double.tryParse(sales.rowTotal) ?? 0;
              salesAmount += sum;
            }
            for (var name in tsmNames) {
              targetAmount += calculateTotalForRep(
                name,
                "1",
                tmpRsmSalesTargetList,
              );
            }
          }
          if (salesAmount + targetAmount > 0) {
            rsmwiseDataList.add(
              RsmwiseData(
                rsmName: rsmName,
                salesAmount: salesAmount,
                targetAmount: targetAmount,
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
    rsmwiseDataList.sort((a, b) => a.salesAmount.compareTo(b.salesAmount));
    rsmwiseSalesList = RsmwiseSalesList(rsmwiseData: rsmwiseDataList);
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
    await _loadSales(userName, userLevel);
    await _loadEachQtrValues();
    await _loadMonthlySalesBarChartData();
    showDrillDownChart = true;
    touchedYearGraph = true;
    showProductSaleChart = true;
    if (UserLevel != "1") {
      await _loadTSMSalesBarChartData(0, "", "", "", "", "", "", "");
      await _loadASMSalesBarChartData(0, "", "", "", "", "", "", "");
      await _loadRSMSalesBarChartData(0, "", "", "", "", "", "", "");
    }
    await _loadMonthlyProductGroupwiseSalesBarChartData(
      0,
      "",
      "",
      "",
      "",
      "",
      "",
      "",
    );
    await _loadMonthlyProductwiseSalesBarChartData(
      0,
      "",
      "",
      "",
      "",
      "",
      "",
      "",
    );
    await _loadMonthlyCustomerStateWiseSalesBarChartData(
      0,
      "",
      "",
      "",
      "",
      "",
      "",
      "",
    );
    await _loadMonthlyCustomerWiseSalesBarChartData(
      0,
      "",
      "",
      "",
      "",
      "",
      "",
      "",
    );
    chartDataLoaded = true;
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
    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;
    clearVariables();
    LoadDates();
    LoadAllQuarterFromToDates();
    final prefs = await SharedPreferences.getInstance();
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    await _loadEachQtrValues();
    await _loadMonthlySalesBarChartData();
    showDrillDownChart = true;
    touchedYearGraph = true;
    showProductSaleChart = true;
    if (UserLevel != "1") {
      await _loadTSMSalesBarChartData(0, "", "", "", "", "", "", "");
      await _loadASMSalesBarChartData(0, "", "", "", "", "", "", "");
      await _loadRSMSalesBarChartData(0, "", "", "", "", "", "", "");
    }
    await _loadMonthlyProductGroupwiseSalesBarChartData(
      0,
      "",
      "",
      "",
      "",
      "",
      "",
      "",
    );
    await _loadMonthlyProductwiseSalesBarChartData(
      0,
      "",
      "",
      "",
      "",
      "",
      "",
      "",
    );
    await _loadMonthlyCustomerStateWiseSalesBarChartData(
      0,
      "",
      "",
      "",
      "",
      "",
      "",
      "",
    );
    await _loadMonthlyCustomerWiseSalesBarChartData(
      0,
      "",
      "",
      "",
      "",
      "",
      "",
      "",
    );
    chartDataLoaded = true;
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
    clearVariablesForFilter();
    LoadDates();
    LoadAllQuarterFromToDates();
    final prefs = await SharedPreferences.getInstance();
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    // await _loadEachQtrValues();
    // await _loadMonthlySalesBarChartData();
    showDrillDownChart = true;
    touchedYearGraph = true;
    showProductSaleChart = true;
    if (UserLevel != "1") {
      await _loadTSMSalesBarChartData(
        monthIndex,
        regionalManager,
        salesManager,
        salesRep,
        stateName,
        customerCode,
        productGroupCode,
        productCode,
      );
      await _loadASMSalesBarChartData(
        monthIndex,
        regionalManager,
        salesManager,
        salesRep,
        stateName,
        customerCode,
        productGroupCode,
        productCode,
      );
      await _loadRSMSalesBarChartData(
        monthIndex,
        regionalManager,
        salesManager,
        salesRep,
        stateName,
        customerCode,
        productGroupCode,
        productCode,
      );
    }

    await _loadMonthlyProductGroupwiseSalesBarChartData(
      monthIndex,
      regionalManager,
      salesManager,
      salesRep,
      stateName,
      customerCode,
      productGroupCode,
      productCode,
    );
    await _loadMonthlyProductwiseSalesBarChartData(
      monthIndex,
      regionalManager,
      salesManager,
      salesRep,
      stateName,
      customerCode,
      productGroupCode,
      productCode,
    );
    await _loadMonthlyCustomerStateWiseSalesBarChartData(
      monthIndex,
      regionalManager,
      salesManager,
      salesRep,
      stateName,
      customerCode,
      productGroupCode,
      productCode,
    );
    await _loadMonthlyCustomerWiseSalesBarChartData(
      monthIndex,
      regionalManager,
      salesManager,
      salesRep,
      stateName,
      customerCode,
      productGroupCode,
      productCode,
    );
    chartDataLoaded = true;
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
    double totalSalesAmount = 0;
    double totalSalesTarget = 0;
    double totalDiff = 0;
    double avgPercentage = 0;
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Month',
          'Sales Target',
          'Sales Amount',
          'Percentage',
          'Difference',
        ]),
      );
      for (var monthlyData in monthlySalesList.monthlyData) {
        sheet.appendRow(
          toCellRow([
            monthlyData.monthName,
            monthlyData.salesTarget,
            monthlyData.salesAmount,
            monthlyData.salesTarget != 0
                ? ((monthlyData.salesAmount / monthlyData.salesTarget) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
            monthlyData.salesAmount - monthlyData.salesTarget,
          ]),
        );
        totalSalesAmount += monthlyData.salesAmount;
        totalSalesTarget += monthlyData.salesTarget;
        totalDiff += (monthlyData.salesAmount - monthlyData.salesTarget);
        avgPercentage += (monthlyData.salesTarget != 0
            ? ((monthlyData.salesAmount / monthlyData.salesTarget) * 100)
                      .ceil() /
                  monthlySalesList.monthlyData.length
            : 0);
      }
      sheet.appendRow(
        toCellRow([
          "",
          totalSalesTarget,
          totalSalesAmount,
          avgPercentage,
          totalDiff,
        ]),
      );

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthly_sales_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_sales_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesPDF(MonthlySalesList monthlySalesList) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Monthly Sales Report',
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
                      'Month',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sales Amount',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sales Target',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Percentage',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Difference',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var monthlyData in monthlySalesList.monthlyData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        monthlyData.monthName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.salesAmount.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.salesTarget.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.salesTarget != 0
                            ? (((monthlyData.salesAmount /
                                          monthlyData.salesTarget) *
                                      100)
                                  .ceil()
                                  .toStringAsFixed(0))
                            : "0"),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.salesAmount - monthlyData.salesTarget)
                            .toString(),
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
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        // Generate bytes
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_sales_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateRsmSalesExcel(RsmwiseSalesList rsmwiseSalesList) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Name',
          'Sales Target',
          'Sales Amount',
          'Percentage',
          'Difference',
        ]),
      );
      for (var rsmData in rsmwiseSalesList.rsmwiseData) {
        sheet.appendRow(
          toCellRow([
            rsmData.rsmName,
            rsmData.targetAmount,
            rsmData.salesAmount,
            rsmData.targetAmount != 0
                ? ((rsmData.salesAmount / rsmData.targetAmount) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
            rsmData.salesAmount - rsmData.targetAmount,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'regional_manager_sales.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('regional_manager_sales.xlsx', excelBytes);
        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'monthly_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/regional_manager_sales.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateRsmSalesPDF(RsmwiseSalesList rsmwiseSalesList) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Regional Managers Sales Report',
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
                      'Name',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sales Amount',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sales Target',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Percentage',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Difference',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var monthlyData in rsmwiseSalesList.rsmwiseData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        monthlyData.rsmName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.salesAmount.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.targetAmount.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.targetAmount != 0
                            ? (((monthlyData.salesAmount /
                                          monthlyData.targetAmount) *
                                      100)
                                  .ceil()
                                  .toStringAsFixed(0))
                            : "0"),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.salesAmount - monthlyData.targetAmount)
                            .toString(),
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
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        final pdfBytes = await pdf.save();

        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_sales_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateAsmSalesExcel(AsmwiseSalesList asmwiseSalesList) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Name',
          'Sales Target',
          'Sales Amount',
          'Percentage',
          'Difference',
        ]),
      );
      for (var asmData in asmwiseSalesList.asmwiseData) {
        sheet.appendRow(
          toCellRow([
            asmData.asmName,
            asmData.targetAmount,
            asmData.salesAmount,
            asmData.targetAmount != 0
                ? ((asmData.salesAmount / asmData.targetAmount) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
            asmData.salesAmount - asmData.targetAmount,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'asm_sales_report.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('asm_sales_report.xlsx', excelBytes);

        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'monthly_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/asm_sales_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateAsmSalesPDF(AsmwiseSalesList asmwiseSalesList) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Managers Sales Report',
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
                      'Name',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sales Amount',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sales Target',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Percentage',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Difference',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var monthlyData in asmwiseSalesList.asmwiseData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        monthlyData.asmName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.salesAmount.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.targetAmount.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.targetAmount != 0
                            ? (((monthlyData.salesAmount /
                                          monthlyData.targetAmount) *
                                      100)
                                  .ceil()
                                  .toStringAsFixed(0))
                            : "0"),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.salesAmount - monthlyData.targetAmount)
                            .toString(),
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
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        final pdfBytes = await pdf.save();

        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_sales_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateTsmSalesExcel(TsmwiseSalesList tsmwiseSalesList) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Name',
          'Sales Target',
          'Sales Amount',
          'Percentage',
          'Difference',
        ]),
      );
      for (var tsmData in tsmwiseSalesList.tsmwiseData) {
        sheet.appendRow(
          toCellRow([
            tsmData.tsmName,
            tsmData.targetAmount,
            tsmData.salesAmount,
            tsmData.targetAmount != 0
                ? ((tsmData.salesAmount / tsmData.targetAmount) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
            tsmData.salesAmount - tsmData.targetAmount,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'tsm_sales_report.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('tsm_sales_report.xlsx', excelBytes);

        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'monthly_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/tsm_sales_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateTsmSalesPDF(TsmwiseSalesList tsmwiseSalesList) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Representatives Sales Report',
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
                      'Name',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sales Amount',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sales Target',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Percentage',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Difference',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var monthlyData in tsmwiseSalesList.tsmwiseData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        monthlyData.tsmName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.salesAmount.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.targetAmount.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.targetAmount != 0
                            ? (((monthlyData.salesAmount /
                                          monthlyData.targetAmount) *
                                      100)
                                  .ceil()
                                  .toStringAsFixed(0))
                            : "0"),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.salesAmount - monthlyData.targetAmount)
                            .toString(),
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
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        final pdfBytes = await pdf.save();

        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_sales_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateCustomerStateSalesExcel(
    CustomerStateWiseSalesList customerStateWiseSalesList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'State Name',
          'Sales Target',
          'Sales Amount',
          'Percentage',
          'Difference',
        ]),
      );
      for (var stateData in customerStateWiseSalesList.customerStateData) {
        sheet.appendRow(
          toCellRow([
            stateData.stateName,
            stateData.targetAmount,
            stateData.saleAmount,
            stateData.targetAmount != 0
                ? ((stateData.saleAmount / stateData.targetAmount) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
            stateData.saleAmount - stateData.targetAmount,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'Customer_state_wise_report.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('customer_state_wise_report.xlsx', excelBytes);

        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'monthly_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/customer_state_wise_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateCustomerStateSalesPDF(
    CustomerStateWiseSalesList customerStateWiseSalesList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Statewise Sales Report',
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
                      'State Name',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sales Amount',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sales Target',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Percentage',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Difference',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var monthlyData
                    in customerStateWiseSalesList.customerStateData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        monthlyData.stateName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.saleAmount.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.targetAmount.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.targetAmount != 0
                            ? (((monthlyData.saleAmount /
                                          monthlyData.targetAmount) *
                                      100)
                                  .ceil()
                                  .toStringAsFixed(0))
                            : "0"),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.saleAmount - monthlyData.targetAmount)
                            .toString(),
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
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        final pdfBytes = await pdf.save();

        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_sales_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateCustomerSalesExcel(
    CustomerWiseSalesList customerWiseSalesList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Customer Name',
          'Sales Target',
          'Sales Amount',
          'Percentage',
          'Difference',
        ]),
      );
      for (var customerData in customerWiseSalesList.customerData) {
        sheet.appendRow(
          toCellRow([
            customerData.customerName,
            customerData.targetAmount,
            customerData.saleAmount,
            customerData.targetAmount != 0
                ? ((customerData.saleAmount / customerData.targetAmount) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
            customerData.saleAmount - customerData.targetAmount,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'Customer_Sales.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('customer_Sales.xlsx', excelBytes);

        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'monthly_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/customer_Sales.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateCustomerSalesPDF(
    CustomerWiseSalesList customerWiseSalesList,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Customer Sales Order Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20;
      final totalPages =
          (customerWiseSalesList.customerData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > customerWiseSalesList.customerData.length
            ? customerWiseSalesList.customerData.length
            : start + rowsPerPage;
        final tableData = customerWiseSalesList.customerData.sublist(
          start,
          end,
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
                        'Customer Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Sales Amount',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Sales Target',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Percentage',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Difference',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.customerName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.saleAmount.toString(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.targetAmount.toString(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          ((monthlyData.saleAmount / monthlyData.targetAmount !=
                                          0
                                      ? monthlyData.targetAmount
                                      : monthlyData.saleAmount) *
                                  100)
                              .ceil()
                              .toStringAsFixed(0),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          (monthlyData.saleAmount - monthlyData.targetAmount)
                              .toString(),
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
      }

      if (kIsWeb) {
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        final pdfBytes = await pdf.save();

        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_sales_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemGroupSalesExcel(
    ProductGroupwiseSalesList productGroupwiseSalesList,
  ) async {
    await _loadMonthlyItemSalesData();
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
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
        ]),
      );
      for (var groupData in ytdItemSalesList.ytdData) {
        sheet.appendRow(
          toCellRow([
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
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'item_group_sales.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('item_group_sales.xlsx', excelBytes);

        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'item_group_sales.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/item_group_sales.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemGroupSalesPDF(
    List<ItemYTDSalesData> productGroupwiseSalesList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Productgroupwise Sales Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20;
      final totalPages = (ytdItemSalesList.ytdData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > ytdItemSalesList.ytdData.length
            ? ytdItemSalesList.ytdData.length
            : start + rowsPerPage;
        final tableData = ytdItemSalesList.ytdData.sublist(start, end);

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
                        'Item Group',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'April',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'May',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Jun',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Q1 Avg',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Jul',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Aug',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Sep',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Q2 Avg',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Oct',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Nov',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Dec',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Q3 Avg',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Jan',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Feb',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Mar',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Q4 Avg',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'YTD Total',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'YTD Avg',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.itemGroup,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.aprValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.mayValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.junValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.q1Avg).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.julValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.augValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.sepValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.q2Avg).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.octValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.novValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.decValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.q3Avg).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.janValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.febValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.marValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.q4Avg).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.ytdTotalValue).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          formatAmount(monthlyData.ytdTotalAvg).toString(),
                          style: pw.TextStyle(
                            fontSize: 8,
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
      }

      if (kIsWeb) {
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        final pdfBytes = await pdf.save();

        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_sales_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemSalesExcel(
    ProductwiseSalesList productwiseSalesList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Product Name',
          'Sales Target',
          'Sales Amount',
          'Percentage',
          'Difference',
        ]),
      );
      for (var itemData in productwiseSalesList.productData) {
        sheet.appendRow(
          toCellRow([
            itemData.productName,
            itemData.targetAmount,
            itemData.salesAmount,
            itemData.targetAmount != 0
                ? ((itemData.salesAmount / itemData.targetAmount) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
            itemData.salesAmount - itemData.targetAmount,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'item_sales_report.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('item_sales_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/item_sales_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemSalesPDF(
    ProductwiseSalesList productwiseSalesList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Productwise Sales Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20;
      final totalPages = (productwiseSalesList.productData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > productwiseSalesList.productData.length
            ? productwiseSalesList.productData.length
            : start + rowsPerPage;
        final tableData = productwiseSalesList.productData.sublist(start, end);

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
                        'Item Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Sales Amount',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Sales Target',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Percentage',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Difference',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.productName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.salesAmount.toString(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.targetAmount.toString(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          (monthlyData.targetAmount != 0
                              ? (((monthlyData.salesAmount /
                                            monthlyData.targetAmount) *
                                        100)
                                    .ceil()
                                    .toStringAsFixed(0))
                              : "0"),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          (monthlyData.salesAmount - monthlyData.targetAmount)
                              .toString(),
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
      }

      if (kIsWeb) {
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        final pdfBytes = await pdf.save();

        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_sales_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesAnalysisYTDExcel() async {
    await _loadYtdSalesBarChartData();
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow([
        'Customer Name',
        'Sales Manager',
        'Sales Representative',
        'Product Category',
        'Product Name',
        // 'Currency',
        // 'Product Rate',
        // 'Product Price',
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
      ]),
    );

    for (int column = 0; column < 34; column++) {
      var cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
      );
      cell.cellStyle = xl.CellStyle(
        // bold: true,
        fontSize: 11,
      );
      //sheet.setColAutoFit(column);
    }

    for (var ytdData in ytdSalesList.ytdData) {
      sheet.appendRow(
        toCellRow([
          ytdData.customerName,
          ytdData.salesManager,
          ytdData.salesRep,
          ytdData.itemSubGroup,
          ytdData.itemName,
          // ytdData.currency,
          // ytdData.currencyRate,
          // ytdData.price,
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
          //xl.CellStyle(),
        ]),
      );
    }

    xl.CellStyle centerCellStyle = xl.CellStyle(
      verticalAlign: xl.VerticalAlign.Center,
      // horizontalAlign: xl.HorizontalAlign.Center,
    );

    int numberOfRows = ytdSalesList.ytdData.length;

    for (int rowIndex = 0; rowIndex <= numberOfRows; rowIndex++) {
      for (int colIndex = 0; colIndex < 34; colIndex++) {
        var cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex,
          ),
        );
        if (rowIndex != 0) {
          cell.cellStyle = centerCellStyle;
        }
      }
    }
    setState(() {
      YtdSalesBarChartData = true;
    });
    if (kIsWeb) {
      final excelBytes = excel.encode()!;
      saveAndOpenExcel('sales_analysis_ytd_report.xlsx', excelBytes);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/sales_analysis_ytd_report.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
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
    await _loadYtdSalesBarChartData();
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow([
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
      ]),
    );

    for (int column = 0; column < 34; column++) {
      var cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
      );
      cell.cellStyle = xl.CellStyle(bold: true, fontSize: 14);

      // sheet.setColAutoFit(column);
    }

    for (var ytdData in ytdSalesList.ytdData) {
      sheet.appendRow(
        toCellRow([
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
        ]),
      );
    }

    xl.CellStyle centerCellStyle = xl.CellStyle(
      verticalAlign: xl.VerticalAlign.Center,
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    int numberOfRows = ytdSalesList.ytdData.length;

    for (int rowIndex = 0; rowIndex <= numberOfRows; rowIndex++) {
      for (int colIndex = 0; colIndex < 34; colIndex++) {
        var cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex,
          ),
        );
        if (rowIndex != 0) {
          cell.cellStyle = centerCellStyle;
        }
      }
    }

    setState(() {
      YtdSalesBarChartData = true;
    });

    if (kIsWeb) {
      // var fileBytes = excel.save(fileName: 'sales_analysis_quarterData.xlsx');

      final excelBytes = excel.encode()!;
      saveAndOpenExcel('sales_analysis_quarterData.xlsx', excelBytes);

      // var fileBytes = excel.encode();
      //
      // final blob = html.Blob([fileBytes]);
      // final url = html.Url.createObjectUrlFromBlob(blob);
      // final anchor = html.AnchorElement()
      //   ..href = url
      //   ..download = 'monthly_sales_report.xlsx'
      //   ..style.display = 'none';
      // html.document.body!.append(anchor);
      // anchor.click();
      // anchor.remove();
      // html.Url.revokeObjectUrl(url);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/sales_analysis_quarterData.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
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
    }
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
    clearVariables();
    _longPressGestureRecognizer.dispose();
    super.dispose();
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
            controller: salesPerformancePageController,
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
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    showLoaderDialog(context);

                                    generateSalesAnalysisYTDExcel();
                                    if (YtdSalesBarChartData == true) {
                                      Navigator.pop(context);
                                    }
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final screenHeight = constraints.maxHeight;

                    final isLandscape = screenWidth > screenHeight;

                    // Adjust sizes responsively
                    final mainRadius = isLandscape
                        ? screenHeight * 0.25
                        : screenHeight * 0.18;
                    final mainLineWidth = isLandscape ? 35.0 : 50.0;

                    final smallRadius = isLandscape
                        ? screenHeight * 0.12
                        : 55.0;
                    final smallLineWidth = isLandscape ? 12.0 : 20.0;

                    final spacingTop = isLandscape ? 20.0 : 70.0;

                    return SizedBox(
                      height: isLandscape
                          ? screenHeight * 0.9
                          : screenHeight / 2.3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          /// MAIN BIG CIRCLE
                          CircularPercentIndicator(
                            arcType: ArcType.HALF,
                            radius: mainRadius,
                            lineWidth: mainLineWidth,
                            animation: true,
                            percent: CurrentMonthSalesPercentage / 100,
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: spacingTop),
                                Text(
                                  CurrentMonthSalesPercentageStr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  CurrentMonthSalesStr,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${getMonthName(currentDate!.month)} Goal - $SalesGoalStr",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            progressColor: Colors.red,
                            arcBackgroundColor: Colors.grey.shade200,
                          ),

                          const SizedBox(height: 10),

                          /// 3 SMALL CIRCLES - USE ROW ONLY (NO POSITIONED)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSmallCircle(
                                radius: smallRadius,
                                lineWidth: smallLineWidth,
                                percent: LastMonthPercentage,
                                percentageStr: LastMonthPercentageStr,
                                salesStr: LastMonthSalesStr,
                                title:
                                    "${getMonthName(currentDate!.month - 1)} Sales ($LastMonthTargetStr)",
                                isSelected: touchedMonthGoals,
                                color: Colors.red,
                                onTap: () {
                                  setState(() {
                                    loadMonthlySalesBarChartDataFromPieChart(1);
                                    _monthlySalesAnalysisChart(
                                      monthlySalesList.monthlyData,
                                    );
                                    showProductSaleChart = false;
                                    showDrillDownChart = false;
                                    lastMonthChartFunc = true;
                                    lastThreeMonthChartFunc = false;
                                    touchedMonthGoals = true;
                                    touchedQuarterGoals = false;
                                    touchedYTDGoals = false;
                                  });
                                },
                              ),

                              _buildSmallCircle(
                                radius: smallRadius,
                                lineWidth: smallLineWidth,
                                percent: CurrentQtrPercentage,
                                percentageStr: CurrentQtrPercentageStr,
                                salesStr: CurrentQtrSalesStr,
                                title:
                                    "Q$currentQuarter Sales ($CurrentQtrTargetStr)",
                                isSelected: touchedQuarterGoals,
                                color: Colors.orange,
                                onTap: () {
                                  setState(() {
                                    lastMonthChartFunc = false;
                                    lastThreeMonthChartFunc = true;
                                    loadMonthlySalesBarChartDataFromPieChart(3);
                                    _monthlySalesAnalysisChart(
                                      monthlySalesList.monthlyData,
                                    );
                                    showProductSaleChart = false;
                                    showDrillDownChart = false;
                                    touchedMonthGoals = false;
                                    touchedQuarterGoals = true;
                                    touchedYTDGoals = false;
                                  });
                                },
                              ),

                              _buildSmallCircle(
                                radius: smallRadius,
                                lineWidth: smallLineWidth,
                                percent: YtdPercentage,
                                percentageStr: YtdPercentageStr,
                                salesStr: YtdSalesStr,
                                title: "YTD ($YtdTargetStr)",
                                isSelected: touchedYTDGoals,
                                color: Colors.green,
                                onTap: () {
                                  setState(() {
                                    _loadMonthlySalesBarChartData();
                                    _monthlySalesAnalysisChart(
                                      monthlySalesList.monthlyData,
                                    );
                                    showProductSaleChart = false;
                                    showDrillDownChart = false;
                                    lastThreeMonthChartFunc = false;
                                    lastMonthChartFunc = false;
                                    touchedMonthGoals = false;
                                    touchedQuarterGoals = false;
                                    touchedYTDGoals = true;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              preferBelow: false,
                              richMessage: WidgetSpan(
                                child: Column(
                                  children: [
                                    const Text(
                                      "Quarter 1 Analysis",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text("Target : $Q1TargetStr"),
                                        Text("Achieved : $Q1SalesStr"),
                                        Text("Difference : $Q1DiffStr"),
                                        Text("Percentage : $Q1PercentageStr"),
                                        Text("Monthly Avg. : $Q1AverageStr"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(4),
                                ),
                              ),
                              showDuration: const Duration(seconds: 7),
                              triggerMode: TooltipTriggerMode.tap,
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xff6CCC3F,
                                      ).withValues(alpha: 0.5),
                                      border: const Border(
                                        left: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        top: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        "Q1",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        top: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Q1PercentageStr != ""
                                          ? Text(Q1PercentageStr)
                                          : const Text("      "),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tooltip(
                              preferBelow: false,
                              richMessage: WidgetSpan(
                                child: Column(
                                  children: [
                                    const Text(
                                      "Quarter 2 Analysis",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text("Target : $Q2TargetStr"),
                                        Text("Achieved : $Q2SalesStr"),
                                        Text("Difference : $Q2DiffStr"),
                                        Text("Percentage : $Q2PercentageStr"),
                                        Text("Monthly Avg. : $Q2AverageStr"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: const Offset(
                                      0,
                                      3,
                                    ), // changes position of shadow
                                  ),
                                ],
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(4),
                                ),
                              ),
                              triggerMode: TooltipTriggerMode.tap,
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFF49136,
                                      ).withValues(alpha: 0.5),
                                      border: const Border(
                                        left: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        top: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        "Q2",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        top: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Q2PercentageStr != ""
                                          ? Text(Q2PercentageStr)
                                          : const Text("      "),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tooltip(
                              preferBelow: false,
                              richMessage: WidgetSpan(
                                child: Column(
                                  children: [
                                    const Text(
                                      "Quarter 3 Analysis",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text("Target : $Q3TargetStr"),
                                        Text("Achieved : $Q3SalesStr"),
                                        Text("Difference : $Q3DiffStr"),
                                        Text("Percentage : $Q3PercentageStr"),
                                        Text("Monthly Avg. : $Q3AverageStr"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: const Offset(
                                      0,
                                      3,
                                    ), // changes position of shadow
                                  ),
                                ],
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(4),
                                ),
                              ),
                              triggerMode: TooltipTriggerMode.tap,
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFE92729,
                                      ).withValues(alpha: 0.5),
                                      border: const Border(
                                        left: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        top: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        "Q3",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        top: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Q3PercentageStr != ""
                                          ? Text(Q3PercentageStr)
                                          : const Text("      "),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tooltip(
                              preferBelow: false,
                              richMessage: WidgetSpan(
                                child: Column(
                                  children: [
                                    const Text(
                                      "Quarter 4 Analysis",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text("Target : $Q4TargetStr"),
                                        Text("Achieved : $Q4SalesStr"),
                                        Text("Difference : $Q4DiffStr"),
                                        Text("Percentage : $Q4PercentageStr"),
                                        Text("Monthly Avg. : $Q4AverageStr"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: const Offset(
                                      0,
                                      3,
                                    ), // changes position of shadow
                                  ),
                                ],
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(4),
                                ),
                              ),
                              triggerMode: TooltipTriggerMode.tap,
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6CCC3F,
                                      ).withValues(alpha: 0.5),
                                      border: const Border(
                                        left: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        top: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        "Q4",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        right: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        top: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Q4PercentageStr != ""
                                          ? Text(Q4PercentageStr)
                                          : const Text("      "),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      onSelected: (value) {},
                      itemBuilder: (BuildContext bc) {
                        return [
                          PopupMenuItem(
                            onTap: () {
                              setState(() {
                                generateSalesAnalysisQuarterDataYTDExcel();
                              });
                            },
                            child: const Text("Download Excel"),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                          "Monthwise Sales Analysis",
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
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Achieved", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFF49136),
                        ),
                        const SizedBox(width: 5),
                        const Text("Goal", style: TextStyle(fontSize: 12)),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSalesExcel(monthlySalesList);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSalesPDF(monthlySalesList);
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
                  padding: const EdgeInsets.all(8.0),
                  child: _buildMonthlySalesChart(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Visibility(
                  visible: rsmwiseSalesList.rsmwiseData.isNotEmpty,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 15),
                          Text(
                            "Regional Manager Analysis",
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
                            color: const Color(0xFF97D7F3),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Achieved",
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            height: 8,
                            width: 8,
                            color: const Color(0xFFF49136),
                          ),
                          const SizedBox(width: 5),
                          const Text("Goal", style: TextStyle(fontSize: 12)),
                          PopupMenuButton(
                            onSelected: (value) {},
                            itemBuilder: (BuildContext bc) {
                              return [
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateRsmSalesExcel(rsmwiseSalesList);
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateRsmSalesPDF(rsmwiseSalesList);
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
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: rsmwiseSalesList.rsmwiseData.isEmpty
                      ? const SizedBox.shrink()
                      : _regionalManagerAnalysis(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: rsmwiseSalesList.rsmwiseData.isEmpty
                      ? const SizedBox.shrink()
                      : const Divider(thickness: 2),
                ),
                Visibility(
                  visible: asmwiseSalesList.asmwiseData.isNotEmpty,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 15),
                          Text(
                            "Sales Manager Analysis",
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
                            color: const Color(0xFF97D7F3),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Achieved",
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            height: 8,
                            width: 8,
                            color: const Color(0xFFF49136),
                          ),
                          const SizedBox(width: 5),
                          const Text("Goal", style: TextStyle(fontSize: 12)),
                          PopupMenuButton(
                            onSelected: (value) {},
                            itemBuilder: (BuildContext bc) {
                              return [
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateAsmSalesExcel(asmwiseSalesList);
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateAsmSalesPDF(asmwiseSalesList);
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
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: asmwiseSalesList.asmwiseData.isEmpty
                      ? const SizedBox.shrink()
                      : _salesManagerAnalysis(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: asmwiseSalesList.asmwiseData.isEmpty
                      ? const SizedBox.shrink()
                      : const Divider(thickness: 2),
                ),
                Visibility(
                  visible: tsmwiseSalesList.tsmwiseData.isNotEmpty,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 15),
                          Text(
                            "Sales Person Analysis",
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
                            color: const Color(0xFF97D7F3),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Achieved",
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            height: 8,
                            width: 8,
                            color: const Color(0xFFF49136),
                          ),
                          const SizedBox(width: 5),
                          const Text("Goal", style: TextStyle(fontSize: 12)),
                          PopupMenuButton(
                            onSelected: (value) {},
                            itemBuilder: (BuildContext bc) {
                              return [
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateTsmSalesExcel(tsmwiseSalesList);
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateTsmSalesPDF(tsmwiseSalesList);
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
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: tsmwiseSalesList.tsmwiseData.isEmpty
                      ? const SizedBox.shrink()
                      : _salesPersonAnalysis(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: tsmwiseSalesList.tsmwiseData.isEmpty
                      ? const SizedBox.shrink()
                      : const Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Customer State \nwise Analysis",
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
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Achieved", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFF49136),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "3 Month Avg.",
                          style: TextStyle(fontSize: 12),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateCustomerStateSalesExcel(
                                      customerStateWiseSalesList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateCustomerStateSalesPDF(
                                      customerStateWiseSalesList,
                                    );
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
                  padding: const EdgeInsets.all(8.0),
                  child: _buildCustomerStateWiseSalesChart(),
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
                          "Customer Analysis",
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
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Achieved", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFF49136),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "3 Month Avg.",
                          style: TextStyle(fontSize: 12),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateCustomerSalesExcel(
                                      customerWiseSalesList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateCustomerSalesPDF(
                                      customerWiseSalesList,
                                    );
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
                  padding: const EdgeInsets.all(8.0),
                  child: _buildCustomerSalesChart(),
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
                          "Item Groupwise \nAnalysis",
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
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Achieved", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFF49136),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "3 Month Avg.",
                          style: TextStyle(fontSize: 12),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemGroupSalesExcel(
                                      itemGroupWiseData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemGroupSalesExcel(
                                      itemGroupWiseData,
                                    );
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
                  padding: const EdgeInsets.all(8.0),
                  child: _itemGroupWiseAnalysis(),
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
                          "Item Analysis",
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
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Achieved", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFF49136),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "3 Month Avg.",
                          style: TextStyle(fontSize: 12),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemSalesExcel(
                                      productwiseSalesList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemSalesPDF(productwiseSalesList);
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
                  padding: const EdgeInsets.all(8.0),
                  child: _itemWiseAnalysis(),
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

  void _scrollDown() {
    salesPerformancePageController.animateTo(
      800, //salesPerformancePageController.position.maxScrollExtent
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  Widget _buildMonthlySalesChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    double barChartWidth = 0.0;
    monthlySalesList.monthlyData.length > 6
        ? barChartWidth = screenWidth * 1.4
        : barChartWidth = screenWidth;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: barChartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(monthlySalesList),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
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
            barGroups: _monthlySalesAnalysisChart(monthlySalesList.monthlyData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    touchedMonth = monthlySalesList
                        .monthlyData[barTouchResponse.spot!.spot.x.toInt()]
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
      return index;
      // return asmwiseData.length > 1 ? index - 1 : index;
    } else {
      return -1; // Indicating that no bar was tapped
    }
  }

  Widget _regionalManagerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = rsmwiseSalesList.rsmwiseData.length;
    if (rsmwiseSalesList.rsmwiseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getRsmMaxValue(rsmwiseSalesList),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
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
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedRegionalManager = touchedRegionalManager == ""
                          ? rsmwiseSalesList
                                .rsmwiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .rsmName
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
                    '${rsmwiseSalesList.rsmwiseData[grpIndex].rsmName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Achievement : ${(rsmwiseSalesList.rsmwiseData[grpIndex].salesAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Target : ${(rsmwiseSalesList.rsmwiseData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Difference : ${((rsmwiseSalesList.rsmwiseData[grpIndex].salesAmount - rsmwiseSalesList.rsmwiseData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Percentage : ${((rsmwiseSalesList.rsmwiseData[grpIndex].salesAmount / rsmwiseSalesList.rsmwiseData[grpIndex].targetAmount) * 100).ceil().toStringAsFixed(0)}%",
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

  Widget _salesManagerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = asmwiseSalesList.asmwiseData.length;
    if (asmwiseSalesList.asmwiseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: GestureDetector(
          onTapDown: (details) {
            setState(() {
              touchedSalesManager = touchedSalesManager == ""
                  ? asmwiseSalesList
                        .asmwiseData[determineGrpIndex(
                          details.localPosition,
                          asmwiseSalesList.asmwiseData,
                          chartWidth,
                        )]
                        .asmName
                  : "";
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
            });
          },
          child: BarChart(
            BarChartData(
              maxY: getAsmMaxValue(asmwiseSalesList),
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
                touchTooltipData: BarTouchTooltipData(
                  maxContentWidth: 200,
                  tooltipBorder: const BorderSide(
                    width: 4.0,
                    color: Colors.black12,
                    style: BorderStyle.none,
                  ),
                  getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                    return BarTooltipItem(
                      '${asmwiseSalesList.asmwiseData[grpIndex].asmName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Achievement : ${(asmwiseSalesList.asmwiseData[grpIndex].salesAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Target : ${(asmwiseSalesList.asmwiseData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Difference : ${((asmwiseSalesList.asmwiseData[grpIndex].salesAmount - asmwiseSalesList.asmwiseData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Percentage : ${((asmwiseSalesList.asmwiseData[grpIndex].salesAmount / asmwiseSalesList.asmwiseData[grpIndex].targetAmount) * 100).ceil().toStringAsFixed(0)}%",
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

  Widget _salesPersonAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = tsmwiseSalesList.tsmwiseData.length;
    if (tsmwiseSalesList.tsmwiseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getTsmMaxValue(tsmwiseSalesList),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
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
            barGroups: _salesPersonAnalysisChart(tsmwiseSalesList.tsmwiseData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSalesRep = touchedSalesRep == ""
                          ? tsmwiseSalesList
                                .tsmwiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .tsmName
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
                    '${tsmwiseSalesList.tsmwiseData[grpIndex].tsmName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Achievement : ${(tsmwiseSalesList.tsmwiseData[grpIndex].salesAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Target : ${(tsmwiseSalesList.tsmwiseData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Difference : ${((tsmwiseSalesList.tsmwiseData[grpIndex].salesAmount - tsmwiseSalesList.tsmwiseData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Percentage : ${((tsmwiseSalesList.tsmwiseData[grpIndex].salesAmount / tsmwiseSalesList.tsmwiseData[grpIndex].targetAmount) * 100).ceil().toStringAsFixed(0)}%",
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

  Widget _buildCustomerStateWiseSalesChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = customerStateWiseSalesList.customerStateData.length;
    if (customerStateWiseSalesList.customerStateData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getCustomerStateMaxValue(customerStateWiseSalesList),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedState = touchedState == ""
                          ? customerStateWiseSalesList
                                .customerStateData[barTouchResponse.spot!.spot.x
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
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
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
        .map((e) => e.saleAmount)
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
      chartMaxY = roundUpToLakhs(maxPositive, 1000000);
      chartMinY = roundDownToLakhs(maxNegative, 250000);
    } else if (hasPositive) {
      double maxPositive = amounts.reduce((a, b) => a > b ? a : b);
      chartMaxY = roundUpToLakhs(maxPositive, 1000000);
      chartMinY = 0;
    } else if (hasNegative) {
      double maxNegative = amounts.reduce((a, b) => a < b ? a : b);
      chartMaxY = 0;
      chartMinY = roundDownToLakhs(maxNegative, 250000);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: barChartWidth,
        child: BarChart(
          BarChartData(
            maxY: chartMaxY,
            minY: chartMinY,
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
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
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getItemGroupMaxValue(productGroupwiseSalesList),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
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
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedProductGroup = touchedProductGroup == ""
                          ? productGroupwiseSalesList
                                .productGroupData[barTouchResponse.spot!.spot.x
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
        .map((e) => e.salesAmount)
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
      chartMaxY = roundUpToLakhs(maxPositive, 500000);
      chartMinY = roundDownToLakhs(maxNegative, 250000);
    } else if (hasPositive) {
      double maxPositive = amounts.reduce((a, b) => a > b ? a : b);
      chartMaxY = roundUpToLakhs(maxPositive, 500000);
      chartMinY = 0;
    } else if (hasNegative) {
      double maxNegative = amounts.reduce((a, b) => a < b ? a : b);
      chartMaxY = 0;
      chartMinY = roundDownToLakhs(maxNegative, 250000);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: barChartWidth,
        child: BarChart(
          BarChartData(
            maxY: chartMaxY,
            minY: chartMinY,
            barTouchData: BarTouchData(
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  if (flTouchEvent is FlTapUpEvent) {
                    setState(() {
                      touchedProduct = touchedProduct == ""
                          ? productwiseSalesList
                                .productData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .productCode
                          : "";
                      // _loadMonthlyCustomerWiseSalesBarChartData(
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
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
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
    );
  }

  Widget _buildSmallCircle({
    required double radius,
    required double lineWidth,
    required double percent,
    required String percentageStr,
    required String salesStr,
    required String title,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: GestureDetector(
        onTap: onTap,
        child: CircularPercentIndicator(
          arcType: ArcType.HALF,
          radius: radius,
          lineWidth: lineWidth,
          animation: true,
          percent: percent / 100,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: radius / 2),
              Text(
                percentageStr,
                style: TextStyle(
                  fontSize: isSelected ? 13 : 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.cyan : Colors.black,
                ),
              ),
              Text(
                salesStr,
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  color: isSelected ? Colors.cyan : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.cyan : Colors.black,
                ),
              ),
            ],
          ),
          progressColor: color,
          arcBackgroundColor: Colors.grey.shade200,
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
