// ignore_for_file: file_names, non_constant_identifier_names, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
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
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';
import 'package:optima/pages/dashboardPages/pdf_helper_web.dart';

import '../../../notificationService.dart';

class PaymentAnalysis extends StatefulWidget {
  const PaymentAnalysis({super.key});

  @override
  State<PaymentAnalysis> createState() => _PaymentAnalysisState();
}

late Future<void> loadDataFuture;
bool chartDataLoaded = false;
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
String UserLevel = "";
int currentQuarter = 0;

List<PaymentAnalysisList> paymentAnalysis = [];
List<ModeOfPaymentList> modeOfPayment = [];

PaymentMonthWiseList monthData = PaymentMonthWiseList(monthlyData: []);
PaymentSupplierAnalysisList supplierData = PaymentSupplierAnalysisList(
  supplierData: [],
);
PaymentSupplierCategoryAnalysisList supplierCategoryData =
    PaymentSupplierCategoryAnalysisList(supplierCategoryData: []);
PaymentSupplierAnalysisList supplierPayableData = PaymentSupplierAnalysisList(
  supplierData: [],
);
PaymentSupplierCategoryAnalysisList supplierPayableCategoryData =
    PaymentSupplierCategoryAnalysisList(supplierCategoryData: []);
PaymentPayableAgingList payableAgingData = PaymentPayableAgingList(
  agingData: [],
);
PaymentModeOfPaymentGraphList modeOfPaymentData = PaymentModeOfPaymentGraphList(
  modeOfPaymentData: [],
);

int touchedMonthIndex = 0;
String touchedMonth = "";
String touchedSupplierCode = "";
String touchedSupplierCategory = "";
String touchedDocumentType = "";
String touchedAgingCatg = "";
double selectedChart = 0;

final List<String> categories = ['Date'];

List<List<String>> filterOptions = [[]];

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

List<String> listOfRSM = [];
List<String> listOfASM = [];
List<String> listOfTSM = [];

double sumOfCustomerCategoryWise = 0;

Map<String, Map<String, bool>> allCategoriesState = {};

int selectedCategoryIndex = 0;

bool fromFilter = false;
List<String> selectedSalesData = [];

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

class PaymentAnalysisProvider with ChangeNotifier {
  List<PaymentAnalysisList> _salesList = [];
  List<PaymentAnalysisList> get salesList => _salesList;
  void updatePOList(List<PaymentAnalysisList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }

  void updateModeOfPaymentList(List<ModeOfPaymentList> newSalesList) {
    notifyListeners();
  }
}

class _PaymentAnalysisState extends State<PaymentAnalysis> {
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  bool showDrillDownChart = false;
  int touchedIndex = -1;

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

  DateTime addDay(DateTime date, int addDays) {
    // Add the specified number of days to the given date
    DateTime newDate = date.add(Duration(days: addDays));

    // Return the resulting date
    return newDate;
  }

  double getMaxValue(double maxValue) {
    double divVal = 0;
    if (maxValue >= 1000000000) {
      divVal = 1000000000;
    } else if (maxValue >= 100000000 && maxValue <= 500000000) {
      divVal = 50000000;
    } else if (maxValue > 50000000 && maxValue <= 100000000) {
      divVal = 10000000;
    } else if (maxValue >= 1000000 && maxValue <= 10000000) {
      divVal = 1000000;
    } else if (maxValue >= 100000 && maxValue <= 1000000) {
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

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  SideTitles get _monthlyBottomTitles =>
      SideTitles(showTitles: true, getTitlesWidget: getMonthwiseBottomTitles);

  Widget getMonthwiseBottomTitles(double val, TitleMeta meta) {
    String text = '';
    PaymentMonthWiseData monthlyPayData = monthData.monthlyData.elementAt(
      val.toInt(),
    );
    text = monthlyPayData.monthName;
    return Text(text.length > 3 ? text.substring(0, 3) : text);
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

  SideTitles get _bottomTitlesSupplierAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<PaymentSupplierAnalysisData> mData = supplierData.supplierData;
      text = mData.elementAt(value.toInt()).supplierName;
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

  SideTitles get _bottomTitlesSupplierPayableAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<PaymentSupplierAnalysisData> mData =
          supplierPayableData.supplierData;
      text = mData.elementAt(value.toInt()).supplierName;
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

  SideTitles get _bottomTitlesSupplierPayableCategoryAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<PaymentSupplierCategoryAnalysisData> mData =
          supplierPayableCategoryData.supplierCategoryData;
      text = mData.elementAt(value.toInt()).supplierCategoryName;
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

  SideTitles get _bottomTitlesSupplierCategoryWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<PaymentSupplierCategoryAnalysisData> mData =
          supplierCategoryData.supplierCategoryData;
      text = mData.elementAt(value.toInt()).supplierCategoryName;
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

  SideTitles get _bottomTitlesModeOfPayment => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<PaymentModeOfPaymentGraphData> mData =
          modeOfPaymentData.modeOfPaymentData;
      text = mData.elementAt(value.toInt()).modeOfPayment;
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

  SideTitles get _bottomTitlesPayableAging => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<PaymentPayableAgingData> mData = payableAgingData.agingData;
      text = mData.elementAt(value.toInt()).agingGroup;
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

  List<BarChartGroupData> _monthWisePaymentAnalysisChartData(
    List<PaymentMonthWiseData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.collectionAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _supplierAnalysisChartData(
    List<PaymentSupplierAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _supplierCategoryWiseAnalysisChartData(
    List<PaymentSupplierCategoryAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _modeOfPaymentChartData(
    List<PaymentModeOfPaymentGraphData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _payableAgingChartData(
    List<PaymentPayableAgingData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.agingGroupTotal,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadPaymentAnalysis(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<PaymentAnalysisList> salesList = [];
    try {
      do {
        var body = {
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

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<PaymentAnalysisList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => PaymentAnalysisList.fromJson(item))
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
        context.read<PaymentAnalysisProvider>().updatePOList(salesList);
        if (int.parse(UserLevel) == 5) {
          paymentAnalysis = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          paymentAnalysis = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          paymentAnalysis = salesList.toList();
        } else {
          paymentAnalysis = salesList.toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading payment data",
      );
    }
  }

  Future<void> _loadModeOfPayment(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<ModeOfPaymentList> salesList = [];
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
        const apiUrl = '${ApiHelper.baseUrl}BicxoPaymentAnalysisList';
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
            List<ModeOfPaymentList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => ModeOfPaymentList.fromJson(item))
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
        context.read<PaymentAnalysisProvider>().updateModeOfPaymentList(
          salesList,
        );
        if (int.parse(UserLevel) == 5) {
          modeOfPayment = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          modeOfPayment = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          modeOfPayment = salesList.toList();
        } else {
          modeOfPayment = salesList.toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading mode of payment data.",
      );
    }
  }

  Future<void> _loadMonthWisePOAnalysis() async {
    List<PaymentMonthWiseData> monthlyDataList = [];
    List inventoryList = modeOfPayment.where((target) {
      return target.vendorGroup.isNotEmpty;
    }).toList();
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    for (int i = 4; i <= 15; i++) {
      String monthName = getMonthName(i);
      double monthlySales = 0.00;

      var monthlySalesList = const Iterable.empty();
      if (i >= 4 && i <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(i);
        monthlySalesList = inventoryList.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!) &&
              target.vendorGroup.toString().isNotEmpty;
        });
      } else {
        startDate = DateTime(currentYear, i - 12, 1);
        endDate = DateTime(currentYear, (i - 12) + 1, 0);
        monthlySalesList = inventoryList.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate) &&
              target.vendorGroup.toString().isNotEmpty;
        });
      }
      double salesAmt = 0;
      for (var target in monthlySalesList.toList()) {
        salesAmt = (double.tryParse(target.total) ?? 0);
        monthlySales += salesAmt;
      }
      monthlyDataList.add(
        PaymentMonthWiseData(
          monthName: monthName,
          collectionAmount: monthlySales.abs(),
        ),
      );
      monthlySales = 0;
      monthData = PaymentMonthWiseList(monthlyData: monthlyDataList);
    }
  }

  Future<void> _loadSupplierAnalysis(
    int monthIndex,
    String vendorName,
    String vendorGroup,
    String documentType,
    String dueDays,
  ) async {
    List<PaymentSupplierAnalysisData> productwiseDataList = [];
    var tempList = filterPaymentList(
      modeOfPayment.cast<ModeOfPaymentList>().toList(),
      vendorName: vendorName,
      vendorGroup: vendorGroup,
      documentType: documentType,
      dueDays: dueDays,
    );
    String vendor = "";
    double productSales = 0.00;

    var productSalesList = const Iterable.empty();
    productSalesList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return (invoiceDate.isAtLeast(fiscalYearStartDate!) &&
          invoiceDate.isAtMost(currentDate!));
    });

    Set<String> processedProductCodes = {};
    for (var product in productSalesList.toList()) {
      if (!processedProductCodes.contains(product.vendorName) &&
          product.vendorGroup.toString().isNotEmpty) {
        vendor = product.vendorName;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.vendorName == vendor,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.total) ?? 0;
          productSales += salesAmt;
        }

        productwiseDataList.add(
          PaymentSupplierAnalysisData(
            supplierName: vendor,
            salesAmount: productSales,
            monthsAvg: productSales / 3,
          ),
        );
        processedProductCodes.add(product.vendorName);
      }
      productSales = 0;
      vendorName = "";
    }
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    supplierData = PaymentSupplierAnalysisList(
      supplierData: productwiseDataList,
    );
  }

  Future<void> _loadSupplierCategoryAnalysis(
    int monthIndex,
    String vendorName,
    String vendorGroup,
    String documentType,
    String dueDays,
  ) async {
    List<PaymentSupplierCategoryAnalysisData> productwiseDataList = [];
    var tempList = filterPaymentList(
      modeOfPayment.cast<ModeOfPaymentList>().toList(),
      vendorName: vendorName,
      vendorGroup: vendorGroup,
      documentType: documentType,
      dueDays: dueDays,
    );
    String vendorGroupName = "";
    double productSales = 0.00;

    var productSalesList = const Iterable.empty();
    productSalesList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return (invoiceDate.isAtLeast(fiscalYearStartDate!) &&
          invoiceDate.isAtMost(currentDate!));
    });

    Set<String> processedVendorGroup = {};
    for (var product in productSalesList.toList()) {
      if (!processedVendorGroup.contains(product.vendorGroup) &&
          product.vendorGroup.toString().isNotEmpty) {
        vendorGroupName = product.vendorGroup;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.vendorGroup == vendorGroupName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.total) ?? 0;
          productSales += salesAmt.abs();
        }

        productwiseDataList.add(
          PaymentSupplierCategoryAnalysisData(
            supplierCategoryName: vendorGroupName,
            salesAmount: productSales,
            monthsAvg: productSales / 3,
          ),
        );
        processedVendorGroup.add(product.vendorGroup);
      }
      productSales = 0;
      vendorGroup = "";
    }
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    supplierCategoryData = PaymentSupplierCategoryAnalysisList(
      supplierCategoryData: productwiseDataList,
    );
  }

  Future<void> _loadSupplierPayableAnalysis(
    int monthIndex,
    String vendorName,
    String vendorGroup,
    String documentType,
    String dueDays,
  ) async {
    List<PaymentSupplierAnalysisData> productwiseDataList = [];
    var tempList = filterPurchaseList(
      paymentAnalysis.cast<PaymentAnalysisList>().toList(),
      vendorName: vendorName,
      vendorGroup: vendorGroup,
      documentType: documentType,
      dueDays: dueDays,
    );
    String vendor = "";
    double productSales = 0.00;

    var productSalesList = const Iterable.empty();
    productSalesList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return (invoiceDate.isAtLeast(fiscalYearStartDate!) &&
          invoiceDate.isAtMost(currentDate!));
    });

    Set<String> processedProductCodes = {};
    for (var product in productSalesList.toList()) {
      if (!processedProductCodes.contains(product.vendorName)) {
        vendor = product.vendorName;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.vendorName == vendor,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.balance) ?? 0;
          productSales += salesAmt.abs();
        }

        productwiseDataList.add(
          PaymentSupplierAnalysisData(
            supplierName: vendor,
            salesAmount: productSales,
            monthsAvg: productSales / 3,
          ),
        );
        processedProductCodes.add(product.vendorName);
      }
      productSales = 0;
      vendorName = "";
    }
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    supplierPayableData = PaymentSupplierAnalysisList(
      supplierData: productwiseDataList,
    );
  }

  Future<void> _loadSupplierPayableCategoryAnalysis(
    int monthIndex,
    String vendorName,
    String vendorGroup,
    String documentType,
    String dueDays,
  ) async {
    List<PaymentSupplierCategoryAnalysisData> productwiseDataList = [];
    var tempList = filterPurchaseList(
      paymentAnalysis.cast<PaymentAnalysisList>().toList(),
      vendorName: vendorName,
      vendorGroup: vendorGroup,
      documentType: documentType,
      dueDays: dueDays,
    );
    String vendorGroupName = "";
    double productSales = 0.00;

    var productSalesList = const Iterable.empty();
    productSalesList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return (invoiceDate.isAtLeast(fiscalYearStartDate!) &&
          invoiceDate.isAtMost(currentDate!));
    });

    Set<String> processedVendorGroup = {};
    for (var product in productSalesList.toList()) {
      if (!processedVendorGroup.contains(product.vendorGroup)) {
        vendorGroupName = product.vendorGroup;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.vendorGroup == vendorGroupName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.balance) ?? 0;
          productSales += salesAmt.abs();
        }

        productwiseDataList.add(
          PaymentSupplierCategoryAnalysisData(
            supplierCategoryName: vendorGroupName,
            salesAmount: productSales,
            monthsAvg: productSales / 3,
          ),
        );
        processedVendorGroup.add(product.vendorGroup);
      }
      productSales = 0;
      vendorGroup = "";
    }
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    supplierPayableCategoryData = PaymentSupplierCategoryAnalysisList(
      supplierCategoryData: productwiseDataList,
    );
  }

  AgingSummary summarizeCollectionTargets(
    Iterable<PaymentAnalysisList> collectionTargetList,
  ) {
    AgingSummary summary = AgingSummary();
    double balance = 0;
    int overDueDays = 0;
    for (var element in collectionTargetList.where(
      (element) => double.tryParse(element.future)! <= 0,
    )) {
      balance = double.tryParse(element.balance) ?? 0;
      overDueDays = int.tryParse(element.dueDays.replaceAll(' Days', '')) ?? 0;
      if (balance < 0) {}
      if (overDueDays <= 30) {
        summary.a0to30DaysTotal += (balance);
        summary.a0to30DaysTotal += double.tryParse(element.a0to30Days)!;
      } else if (overDueDays >= 31 && overDueDays <= 60) {
        summary.a31to60DaysTotal += balance;
        summary.a31to60DaysTotal += double.tryParse(element.a31to60Days)!;
      } else if (overDueDays >= 61 && overDueDays <= 90) {
        summary.a61to90DaysTotal += balance;
        summary.a61to90DaysTotal += double.tryParse(element.a61to90Days)!;
      } else if (overDueDays >= 91 && overDueDays <= 180) {
        summary.a91to180DaysTotal += balance;
        summary.a91to180DaysTotal += double.tryParse(element.a91to180Days)!;
      } else if (overDueDays >= 181) {
        summary.a181DaysTotal += balance;
        summary.a181DaysTotal += double.tryParse(element.a181Days)!;
      }
      summary.afutureTotal += balance;
      summary.afutureTotal += double.tryParse(element.future)!;
    }
    return summary;
  }

  Future<void> _loadPayablesData(
    int monthIndex,
    String vendorName,
    String vendorGroup,
    String documentType,
    String dueDays,
  ) async {
    List<PaymentPayableAgingData> receivablesAgingDataList = [];
    double agingGroup0Total = 0;
    double agingGroup1Total = 0;
    double agingGroup2Total = 0;
    double agingGroup3Total = 0;
    double agingGroup4Total = 0;
    double agingGroup5Total = 0;
    double totalDueAmount = 0;
    var tempList = filterPurchaseList(
      paymentAnalysis.cast<PaymentAnalysisList>().toList(),
      vendorName: vendorName,
      vendorGroup: vendorGroup,
      documentType: documentType,
      dueDays: dueDays,
    );
    var collectionTargetList = tempList.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return dueon.isAtMost(currentMonthToDate!);
    });

    AgingSummary summary = summarizeCollectionTargets(collectionTargetList);
    agingGroup0Total = summary.afutureTotal.abs();
    agingGroup1Total = summary.a0to30DaysTotal.abs();
    agingGroup2Total = summary.a31to60DaysTotal.abs();
    agingGroup3Total = summary.a61to90DaysTotal.abs();
    agingGroup4Total = summary.a91to180DaysTotal.abs();
    agingGroup5Total = summary.a181DaysTotal.abs();
    totalDueAmount =
        agingGroup1Total +
        agingGroup2Total +
        agingGroup3Total +
        agingGroup4Total;
    receivablesAgingDataList.add(
      PaymentPayableAgingData(
        agingGroup: "Future",
        agingGroupTotal: agingGroup0Total,
        agingPercentage: 0,
        agingTotal: totalDueAmount,
      ),
    );
    receivablesAgingDataList.add(
      PaymentPayableAgingData(
        agingGroup: "0-30",
        agingGroupTotal: agingGroup1Total,
        agingPercentage: 0,
        agingTotal: totalDueAmount,
      ),
    );
    receivablesAgingDataList.add(
      PaymentPayableAgingData(
        agingGroup: "31-60",
        agingGroupTotal: agingGroup2Total,
        agingPercentage: 0,
        agingTotal: totalDueAmount,
      ),
    );
    receivablesAgingDataList.add(
      PaymentPayableAgingData(
        agingGroup: "61-90",
        agingGroupTotal: agingGroup3Total,
        agingPercentage: 0,
        agingTotal: totalDueAmount,
      ),
    );
    receivablesAgingDataList.add(
      PaymentPayableAgingData(
        agingGroup: "91-180",
        agingGroupTotal: agingGroup4Total,
        agingPercentage: 0,
        agingTotal: totalDueAmount,
      ),
    );
    receivablesAgingDataList.add(
      PaymentPayableAgingData(
        agingGroup: "180+",
        agingGroupTotal: agingGroup5Total,
        agingPercentage: 0,
        agingTotal: totalDueAmount,
      ),
    );

    for (PaymentPayableAgingData agingData in receivablesAgingDataList) {
      agingData.agingPercentage =
          double.tryParse(
            ((agingData.agingGroupTotal / totalDueAmount) * 100)
                .toStringAsFixed(2),
          ) ??
          0;
      agingData.agingGroupTotal =
          double.tryParse((agingData.agingGroupTotal).toStringAsFixed(2)) ?? 0;
    }
    payableAgingData = PaymentPayableAgingList(
      agingData: receivablesAgingDataList,
    );
  }

  Future<void> _loadModeOfPaymentGraph(
    int monthIndex,
    String vendorName,
    String vendorGroup,
    String documentType,
    String dueDays,
  ) async {
    List<PaymentModeOfPaymentGraphData> productwiseDataList = [];
    var tempList = filterPaymentList(
      modeOfPayment.cast<ModeOfPaymentList>().toList(),
      vendorName: vendorName,
      vendorGroup: vendorGroup,
      documentType: documentType,
      dueDays: dueDays,
    );
    String modeofPayment = "";
    double productSales = 0.00;
    var productSalesList = const Iterable.empty();
    productSalesList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return invoiceDate.isAtLeast(
            /*monthDates['start']*/ fiscalYearStartDate!,
          ) &&
          invoiceDate.isAtMost(/*monthDates['end']*/ currentDate!);
    });

    Set<String> processedModes = {};
    for (var product in productSalesList.toList()) {
      if (!processedModes.contains(product.modeofPayment) &&
          product.vendorGroup.toString().isNotEmpty) {
        modeofPayment = product.modeofPayment;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.modeofPayment == modeofPayment,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.total) ?? 0;
          productSales += salesAmt;
        }

        productwiseDataList.add(
          PaymentModeOfPaymentGraphData(
            modeOfPayment: modeofPayment,
            salesAmount: productSales,
            monthsAvg: productSales / 3,
          ),
        );
        processedModes.add(product.modeofPayment);
      }
      productSales = 0;
      modeofPayment = "";
    }
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    modeOfPaymentData = PaymentModeOfPaymentGraphList(
      modeOfPaymentData: productwiseDataList,
    );
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadPaymentAnalysis(userName, userLevel);
    await _loadModeOfPayment(userName, userLevel);
    await _loadMonthWisePOAnalysis();
    await _loadSupplierAnalysis(0, "", "", "", "");
    await _loadSupplierCategoryAnalysis(0, "", "", "", "");
    await _loadSupplierPayableAnalysis(0, "", "", "", "");
    await _loadSupplierPayableCategoryAnalysis(0, "", "", "", "");
    await _loadPayablesData(0, "", "", "", "");
    await _loadModeOfPaymentGraph(0, "", "", "", "");
    setState(() {
      filterOptions = [[]];

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

  List<PaymentAnalysisList> filterPurchaseList(
    List<PaymentAnalysisList> payList, {
    String? vendorName,
    String? vendorGroup,
    String? documentType,
    String? dueDays,
  }) {
    List<PaymentAnalysisList> filteredPayList = [];
    double dueFrom = 0.0;
    double dueTo = 0.0;
    if (dueDays != null || dueDays != "") {
      if (dueDays == "Future") {
        dueFrom = 0;
        dueTo = 0;
      } else if (dueDays == "0-30") {
        dueFrom = 0;
        dueTo = 30;
      } else if (dueDays == "31-60") {
        dueFrom = 31;
        dueTo = 60;
      } else if (dueDays == "61-90") {
        dueFrom = 61;
        dueTo = 90;
      } else if (dueDays == "91-180") {
        dueFrom = 91;
        dueTo = 180;
      } else if (dueDays == "181+") {
        dueFrom = 181;
        dueTo = dueTo = double.infinity;
      }
    }
    for (var pay in payList) {
      int overDueDays = int.tryParse(pay.dueDays.replaceAll(' Days', '')) ?? 0;
      double future = double.tryParse(pay.future)!;
      if ((vendorName == null ||
              vendorName.isEmpty ||
              pay.vendorName == vendorName) &&
          (vendorGroup == null ||
              vendorGroup.isEmpty ||
              pay.vendorGroup == vendorGroup) &&
          (documentType == null ||
              documentType.isEmpty ||
              pay.documentType == documentType) &&
          ((dueDays == null || dueDays.isEmpty) ||
              (dueDays == "Future" &&
                  future.abs() >
                      0) || // Apply future filter if dueDays is "Future"
              (dueDays != "Future" &&
                  dueFrom >= 0 &&
                  dueTo != 0 &&
                  overDueDays >= dueFrom &&
                  overDueDays <= dueTo))) {
        filteredPayList.add(pay);
      }
    }
    return filteredPayList;
  }

  List<ModeOfPaymentList> filterPaymentList(
    List<ModeOfPaymentList> payList, {
    String? vendorName,
    String? vendorGroup,
    String? documentType,
    String? dueDays,
  }) {
    List<ModeOfPaymentList> filteredPayList = [];
    for (var pay in payList) {
      if ((vendorName == null ||
              vendorName.isEmpty ||
              pay.vendorName == vendorName) &&
          (vendorGroup == null ||
              vendorGroup.isEmpty ||
              pay.vendorGroup == vendorGroup) &&
          (documentType == null ||
              documentType.isEmpty ||
              pay.modeofPayment == documentType)) {
        filteredPayList.add(pay);
      }
    }
    return filteredPayList;
  }

  Future<void> removeFilter() async {
    touchedMonthIndex = 0;
    touchedSupplierCode = "";
    touchedSupplierCategory = "";
    touchedDocumentType = "";
    touchedAgingCatg = "";
    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;
    clearVariables();
    LoadDates();
    setState(() {
      setState(() {
        chartDataLoaded = false;
      });
      clearVariables();
      LoadDates();
      allCategoriesState.forEach((category, options) {
        options.updateAll((key, value) => false);
      });
      allCategoriesState.clear();
      loadDataFuture = loadData("");
      setState(() {
        chartDataLoaded = false;
      });
    });
    chartDataLoaded = true;
  }

  Future<void> loadDataWithFilter(
    int monthIndex,
    String vendorName,
    String vendorGroup,
    String documentType,
    String dueDays,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    await _loadSupplierAnalysis(
      monthIndex,
      vendorName,
      vendorGroup,
      documentType,
      dueDays,
    );
    await _loadSupplierCategoryAnalysis(
      monthIndex,
      vendorName,
      vendorGroup,
      documentType,
      dueDays,
    );
    await _loadPayablesData(
      monthIndex,
      vendorName,
      vendorGroup,
      documentType,
      dueDays,
    );
    await _loadModeOfPaymentGraph(
      monthIndex,
      vendorName,
      vendorGroup,
      documentType,
      dueDays,
    );
    chartDataLoaded = true;
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;
      touchedMonthIndex = 0;
      touchedSupplierCode = "";
      touchedSupplierCategory = "";
      touchedDocumentType = "";
      touchedAgingCatg = "";
      supplierData = PaymentSupplierAnalysisList(supplierData: []);
      supplierCategoryData = PaymentSupplierCategoryAnalysisList(
        supplierCategoryData: [],
      );
      payableAgingData = PaymentPayableAgingList(agingData: []);
      modeOfPaymentData = PaymentModeOfPaymentGraphList(modeOfPaymentData: []);
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoaded = false;
      supplierData = PaymentSupplierAnalysisList(supplierData: []);
      supplierCategoryData = PaymentSupplierCategoryAnalysisList(
        supplierCategoryData: [],
      );
      payableAgingData = PaymentPayableAgingList(agingData: []);
      modeOfPaymentData = PaymentModeOfPaymentGraphList(modeOfPaymentData: []);
    });
  }

  Future<void> generateModeOfPaymentPurchaseExcel(
    PaymentModeOfPaymentGraphList modeOfPaymentData,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Aging Group', 'Collection']));
      for (var itemData in modeOfPaymentData.modeOfPaymentData) {
        sheet.appendRow(
          toCellRow([itemData.modeOfPayment, itemData.salesAmount]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('modeOfPaymentCollection.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/modeOfPaymentCollection.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateModeOfPaymentPurchasePDF(
    PaymentModeOfPaymentGraphList data,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Payable Aging Collection',
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
          (modeOfPaymentData.modeOfPaymentData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > modeOfPaymentData.modeOfPaymentData.length
            ? modeOfPaymentData.modeOfPaymentData.length
            : start + rowsPerPage;
        final tableData = modeOfPaymentData.modeOfPaymentData.sublist(
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
                        'Mode Of Payment',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Collection',
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
                          monthlyData.modeOfPayment,
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
                      ],
                    ),
                ],
              );
            },
          ),
        );
      }

      if (kIsWeb) {
        final pdfBytes = await pdf.save();

        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/modeOfPayment.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generatePayableAgingPurchaseExcel(
    PaymentPayableAgingList payableAgingData,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Aging Group', 'Collection']));
      for (var itemData in payableAgingData.agingData) {
        sheet.appendRow(
          toCellRow([itemData.agingGroup, itemData.agingGroupTotal]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'item_sales_report.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('supplierPayableAgingCollection.xlsx', excelBytes);

        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'item_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/supplierPayableAgingCollection.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generatePayableAgingPurchasePDF(
    PaymentPayableAgingList data,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Payable Aging Collection',
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
      final totalPages = (payableAgingData.agingData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > payableAgingData.agingData.length
            ? payableAgingData.agingData.length
            : start + rowsPerPage;
        final tableData = payableAgingData.agingData.sublist(start, end);

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
                        'Aging Group',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Collection',
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
                          monthlyData.agingGroup,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.agingGroupTotal.toString(),
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
        final file = File('$storageDir/supplierPayableAgingCollection.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierCategoryPayablePurchaseExcel(
    PaymentSupplierCategoryAnalysisList supplierPayableCategoryData,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Category', 'Collection']));
      for (var itemData in supplierPayableCategoryData.supplierCategoryData) {
        sheet.appendRow(
          toCellRow([itemData.supplierCategoryName, itemData.salesAmount]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'item_sales_report.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('supplierCategoryPayableCollection.xlsx', excelBytes);

        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'item_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/supplierCategoryPayableCollection.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierCategoryPayablePurchasePDF(
    PaymentSupplierCategoryAnalysisList data,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier Category Payable Collection',
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
          (supplierPayableCategoryData.supplierCategoryData.length /
                  rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                supplierPayableCategoryData.supplierCategoryData.length
            ? supplierPayableCategoryData.supplierCategoryData.length
            : start + rowsPerPage;
        final tableData = supplierPayableCategoryData.supplierCategoryData
            .sublist(start, end);

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
                        'Category',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Collection',
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
                          monthlyData.supplierCategoryName,
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
        final file = File('$storageDir/supplierCategoryPayableCollection.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierPayablePurchaseExcel(
    PaymentSupplierAnalysisList supplierPayableData,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Supplier', 'Collection']));
      for (var itemData in supplierPayableData.supplierData) {
        sheet.appendRow(
          toCellRow([itemData.supplierName, itemData.salesAmount]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'item_sales_report.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('supplierPayableCollection.xlsx', excelBytes);

        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'item_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/supplierPayableCollection.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierPayablePurchasePDF(
    PaymentSupplierAnalysisList data,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier Payable Collection',
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
      final totalPages = (supplierPayableData.supplierData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > supplierPayableData.supplierData.length
            ? supplierPayableData.supplierData.length
            : start + rowsPerPage;
        final tableData = supplierPayableData.supplierData.sublist(start, end);

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
                        'Category',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Collection',
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
                          monthlyData.supplierName,
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
        final file = File('$storageDir/supplierPayableCollection.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierCategoryPurchaseExcel(
    PaymentSupplierCategoryAnalysisList supplierCategoryData,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Category', 'Collection']));
      for (var itemData in supplierCategoryData.supplierCategoryData) {
        sheet.appendRow(
          toCellRow([itemData.supplierCategoryName, itemData.salesAmount]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'item_sales_report.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('supplierCategoryCollection.xlsx', excelBytes);

        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'item_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/supplierCategoryCollection.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierCategoryPurchasePDF(
    PaymentSupplierCategoryAnalysisList data,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier Category Collection',
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
          (supplierCategoryData.supplierCategoryData.length / rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                supplierCategoryData.supplierCategoryData.length
            ? supplierCategoryData.supplierCategoryData.length
            : start + rowsPerPage;
        final tableData = supplierCategoryData.supplierCategoryData.sublist(
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
                        'Category',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Collection',
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
                          monthlyData.supplierCategoryName,
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
        final file = File('$storageDir/supplierCategoryCollection.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyPurchaseExcel(
    PaymentMonthWiseList monthData,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Month', 'Collection']));
      for (var itemData in monthData.monthlyData) {
        sheet.appendRow(
          toCellRow([itemData.monthName, itemData.collectionAmount]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'item_sales_report.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthCollection.xlsx', excelBytes);

        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'item_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthCollection.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyPurchasePDF(PaymentMonthWiseList month) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Monthly Collection',
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
      final totalPages = (monthData.monthlyData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > monthData.monthlyData.length
            ? monthData.monthlyData.length
            : start + rowsPerPage;
        final tableData = monthData.monthlyData.sublist(start, end);

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
                        'Collection',
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
                          monthlyData.monthName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.collectionAmount.toString(),
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
        final file = File('$storageDir/monthCollection.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierPurchaseExcel(
    PaymentSupplierAnalysisList supplierData,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Supplier Name', 'Collection']));
      for (var itemData in supplierData.supplierData) {
        sheet.appendRow(
          toCellRow([itemData.supplierName, itemData.salesAmount]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.save(fileName: 'item_sales_report.xlsx');

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('supplierCollection.xlsx', excelBytes);

        // var fileBytes = excel.encode();
        //
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'item_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/supplierCollection.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierPurchasePDF(
    PaymentSupplierAnalysisList data,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier Collection',
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
      final totalPages = (supplierData.supplierData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > supplierData.supplierData.length
            ? supplierData.supplierData.length
            : start + rowsPerPage;
        final tableData = supplierData.supplierData.sublist(start, end);

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
                        'Supplier',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Collection',
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
                          monthlyData.supplierName,
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
        final file = File('$storageDir/supplierCollection.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
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

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  Future<void> _dateFilterTarget(
    String UserName,
    String UserLevel,
    bool FromFilter,
  ) async {
    setState(() {
      // List<String> menuNames = usersList
      //     .where((element) => element.parentMenuId == 0)
      //     .map((user) => user.menuName)
      //     .toList();
      // menuNames.insert(0, UserName);
      context.read<PaymentAnalysisProvider>().updatePOList(paymentAnalysis);

      paymentAnalysis = paymentAnalysis.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();
    });
  }

  Future<void> filterFunction() async {
    setState(() {
      chartDataLoaded = false;
    });
    String selectedUser = '';
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    setState(() async {
      await _loadPaymentAnalysis(userName, userLevel);
      await _loadModeOfPayment(userName, userLevel);
      _dateFilterTarget("", "", false);
      await _loadMonthWisePOAnalysis();
      await _loadSupplierAnalysis(0, "", "", "", "");
      await _loadSupplierCategoryAnalysis(0, "", "", "", "");
      await _loadSupplierPayableAnalysis(0, "", "", "", "");
      await _loadSupplierPayableCategoryAnalysis(0, "", "", "", "");
      await _loadPayablesData(0, "", "", "", "");
      await _loadModeOfPaymentGraph(0, "", "", "", "");

      chartDataLoaded = true;

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

        // selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
      });

      setState(() {
        chartDataLoaded = true;
      });
    });
  }

  void resetFinanceReceivablesOptions() {
    setState(() {
      savedFinanceReceivablesOptions = List.from(
        selectedFinanceReceivablesOptions,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
      toDateFilter = currentDate;
      fromDateFilter = fiscalYearStartDate;
    }

    filterOptions = [[]];

    selectedFinanceReceivablesOptions = filterOptions
        .map((options) => List<bool>.filled(options.length, false))
        .toList();

    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
  }

  @override
  Widget build(BuildContext context) {
    // String formattedFiscalYearStartDate = DateFormat(
    //   'dd/MM/yy',
    // ).format(fiscalYearStartDate!);
    // String formattedQuarterStartDate = DateFormat(
    //   'dd/MM/yy',
    // ).format(currentQuarterFromDate!);
    // String formattedQuarterLastDate = DateFormat(
    //   'dd/MM/yy',
    // ).format(currentQuarterToDate!);
    // String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    // String formattedDateFirstOfLastMonth = DateFormat(
    //   'dd/MM/yy',
    // ).format(DateTime(currentDate!.year, currentDate!.month - 1, 1));
    // String formattedDateLastOfLastMonth = DateFormat(
    //   'dd/MM/yy',
    // ).format(DateTime(currentDate!.year, currentDate!.month, 0));
    // String formattedDateFirstOfThisMonth = DateFormat(
    //   'dd/MM/yy',
    // ).format(DateTime(currentDate!.year, currentDate!.month, 1));
    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
    return chartDataLoaded == true
        ? SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Row(
                    //   children: [
                    //     const SizedBox(width: 15),
                    //     touchedMonthGoals == true
                    //         ? Text(
                    //             "$formattedDateFirstOfLastMonth - $formattedDateLastOfLastMonth",
                    //           )
                    //         : touchedQuarterGoals == true
                    //         ? Text(
                    //             "$formattedQuarterStartDate - $formattedQuarterLastDate",
                    //           )
                    //         : touchedYTDGoals == true
                    //         ? Text(
                    //             "$formattedFiscalYearStartDate - $formattedDateNow",
                    //           )
                    //         : Text(
                    //             "$formattedDateFirstOfThisMonth - $formattedDateNow",
                    //           ),
                    //   ],
                    // ),
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
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Month Wise Payment Analysis",
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
                                    generateMonthlyPurchaseExcel(monthData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthlyPurchasePDF(monthData);
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
                  child: _monthWisePaymentAnalysis(),
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
                          "Supplier Analysis",
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
                                    generateSupplierPurchaseExcel(supplierData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierPurchasePDF(supplierData);
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
                  child: _supplierAnalysis(),
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
                          "Supplier Category Wise Analysis",
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
                                    generateSupplierCategoryPurchaseExcel(
                                      supplierCategoryData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierCategoryPurchasePDF(
                                      supplierCategoryData,
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
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _supplierCategoryWiseAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Visibility(
                  visible: true,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 15),
                              Text(
                                "Mode of Payment",
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
                                          generateModeOfPaymentPurchaseExcel(
                                            modeOfPaymentData,
                                          );
                                        });
                                      },
                                      child: const Text("Download Excel"),
                                    ),
                                    PopupMenuItem(
                                      onTap: () {
                                        setState(() {
                                          generateModeOfPaymentPurchasePDF(
                                            modeOfPaymentData,
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
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: _modeOfPaymentAnalysis(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Divider(thickness: 2),
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
                          "Payable Aging",
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
                                    generatePayableAgingPurchaseExcel(
                                      payableAgingData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generatePayableAgingPurchasePDF(
                                      payableAgingData,
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
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _payableAging(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Supplier Payable Analysis",
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
                                    generateSupplierPayablePurchaseExcel(
                                      supplierPayableData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierPayablePurchasePDF(
                                      supplierPayableData,
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
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _supplierPayableAnalysis(),
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
                          "Supplier Category wise Payable Analysis",
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
                                    generateSupplierCategoryPayablePurchaseExcel(
                                      supplierPayableCategoryData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierCategoryPayablePurchasePDF(
                                      supplierPayableCategoryData,
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
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _supplierCategoryWisePayableAnalysis(),
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

  Widget _monthWisePaymentAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    int len = monthData.monthlyData.length;
    double barChartWidth = 0.0;
    monthData.monthlyData.length > 6
        ? barChartWidth = screenWidth * 1.4
        : barChartWidth = screenWidth;

    double maxPurchaseAmount = len > 0
        ? monthData.monthlyData
              .map((data) => data.collectionAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: barChartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxPurchaseAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _monthlyBottomTitles,
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
            barGroups: _monthWisePaymentAnalysisChartData(
              monthData.monthlyData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    touchedMonth = monthData
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
                        touchedSupplierCode,
                        touchedSupplierCategory,
                        touchedDocumentType,
                        touchedAgingCatg,
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
                    monthData.monthlyData[grpIndex].monthName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(monthData.monthlyData[grpIndex].collectionAmount)}",
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

  Widget _supplierAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = supplierData.supplierData.length;
    if (supplierData.supplierData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxPurchaseAmount = len > 0
        ? supplierData.supplierData
              .map((data) => data.salesAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxPurchaseAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesSupplierAnalysis,
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
            barGroups: _supplierAnalysisChartData(supplierData.supplierData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplierCode = touchedSupplierCode == ""
                          ? supplierData
                                .supplierData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .supplierName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedSupplierCode,
                        touchedSupplierCategory,
                        touchedDocumentType,
                        touchedAgingCatg,
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
                    supplierData.supplierData[grpIndex].supplierName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(supplierData.supplierData[grpIndex].salesAmount)}",
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

  Widget _supplierCategoryWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = supplierCategoryData.supplierCategoryData.length;
    if (supplierCategoryData.supplierCategoryData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? supplierCategoryData.supplierCategoryData
              .map((data) => data.salesAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxPurchaseAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesSupplierCategoryWiseAnalysis,
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
            barGroups: _supplierCategoryWiseAnalysisChartData(
              supplierCategoryData.supplierCategoryData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplierCategory = touchedSupplierCategory == ""
                          ? supplierCategoryData
                                .supplierCategoryData[barTouchResponse
                                    .spot!
                                    .spot
                                    .x
                                    .toInt()]
                                .supplierCategoryName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedSupplierCode,
                        touchedSupplierCategory,
                        touchedDocumentType,
                        touchedAgingCatg,
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
                    supplierCategoryData
                        .supplierCategoryData[grpIndex]
                        .supplierCategoryName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(supplierCategoryData.supplierCategoryData[grpIndex].salesAmount)}",
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

  Widget _modeOfPaymentAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = modeOfPaymentData.modeOfPaymentData.length;
    if (modeOfPaymentData.modeOfPaymentData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? modeOfPaymentData.modeOfPaymentData
              .map((data) => data.salesAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxPurchaseAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesModeOfPayment,
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
            barGroups: _modeOfPaymentChartData(
              modeOfPaymentData.modeOfPaymentData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedDocumentType = touchedDocumentType == ""
                          ? modeOfPaymentData
                                .modeOfPaymentData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .modeOfPayment
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedSupplierCode,
                        touchedSupplierCategory,
                        touchedDocumentType,
                        touchedAgingCatg,
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
                    modeOfPaymentData.modeOfPaymentData[grpIndex].modeOfPayment,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(modeOfPaymentData.modeOfPaymentData[grpIndex].salesAmount)}",
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

  Widget _payableAging() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = payableAgingData.agingData.length;
    if (payableAgingData.agingData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? payableAgingData.agingData
              .map((data) => data.agingGroupTotal)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxPurchaseAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesPayableAging,
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
            barGroups: _payableAgingChartData(payableAgingData.agingData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedAgingCatg = touchedAgingCatg == ""
                          ? payableAgingData
                                .agingData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .agingGroup
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedSupplierCode,
                        touchedSupplierCategory,
                        touchedDocumentType,
                        touchedAgingCatg,
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
                    payableAgingData.agingData[grpIndex].agingGroup,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(payableAgingData.agingData[grpIndex].agingGroupTotal)}",
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

  Widget _supplierPayableAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = supplierPayableData.supplierData.length;
    if (supplierPayableData.supplierData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxPurchaseAmount = len > 0
        ? supplierPayableData.supplierData
              .map((data) => data.salesAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxPurchaseAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesSupplierPayableAnalysis,
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
            barGroups: _supplierAnalysisChartData(
              supplierPayableData.supplierData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplierCode = touchedSupplierCode == ""
                          ? supplierData
                                .supplierData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .supplierName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedSupplierCode,
                        touchedSupplierCategory,
                        touchedDocumentType,
                        touchedAgingCatg,
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
                    supplierPayableData.supplierData[grpIndex].supplierName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(supplierPayableData.supplierData[grpIndex].salesAmount)}",
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

  Widget _supplierCategoryWisePayableAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = supplierPayableCategoryData.supplierCategoryData.length;
    if (supplierPayableCategoryData.supplierCategoryData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? supplierPayableCategoryData.supplierCategoryData
              .map((data) => data.salesAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxPurchaseAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesSupplierPayableCategoryAnalysis,
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
            barGroups: _supplierCategoryWiseAnalysisChartData(
              supplierPayableCategoryData.supplierCategoryData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplierCategory = touchedSupplierCategory == ""
                          ? supplierPayableCategoryData
                                .supplierCategoryData[barTouchResponse
                                    .spot!
                                    .spot
                                    .x
                                    .toInt()]
                                .supplierCategoryName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedSupplierCode,
                        touchedSupplierCategory,
                        touchedDocumentType,
                        touchedAgingCatg,
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
                    supplierPayableCategoryData
                        .supplierCategoryData[grpIndex]
                        .supplierCategoryName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(supplierPayableCategoryData.supplierCategoryData[grpIndex].salesAmount)}",
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
