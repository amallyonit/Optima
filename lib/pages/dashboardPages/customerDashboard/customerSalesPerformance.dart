// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/widgets.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import '../../../classes/leads.dart';
import '../../../login_screen.dart';

bool loadingComplete = false;

class Distributor {
  String CustomerName;
  String CustomerCode;
  Distributor({required this.CustomerCode, required this.CustomerName});
}

class CustomerSalesPerformancePage extends StatefulWidget {
  final String customerCode;
  const CustomerSalesPerformancePage({super.key, required this.customerCode});

  @override
  CustomerSalesPerformancePageState createState() =>
      CustomerSalesPerformancePageState();
}

class SalesTargetListCustomerSalesPerformancePageProvider with ChangeNotifier {
  List<SalesTargetList> _salesTargetList = [];
  List<SalesTargetList> get salesTargetList => _salesTargetList;
  void updateSalesTargetList(List<SalesTargetList> newSalesTargetList) {
    _salesTargetList = newSalesTargetList;
    notifyListeners();
  }
}

class SalesListCustomerSalesPerformancePageProvider with ChangeNotifier {
  List<SalesList> _salesList = [];
  List<SalesList> get salesList => _salesList;
  void updateSalesList(List<SalesList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

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

String deviceOrientation = "";
String UserLevel = "0";
String touchedMonth = "";
double maxMonthY = 0.0;
double barChartWidthProduct = 0.0;
double maxItemMonthY = 0.0;
double selectedChart = 0;
List<MyNode> nodes = [];
List<Map<String, dynamic>> userList = [];
List<Users> usersList = [];
List<Users> childUsers = [];
List<Map<String, dynamic>> salesTargetList = [];
late Future<void> loadDataFuture;
List<SalesTargetList> salesTarget = [];
String SalesGoalStr = "";
String CollectionsStr = "";
String CurrentMonthSalesStr = "";
double CurrentMonthSales = 0;
double SalesGoal = 0;
double Collections = 0;
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
double CollectionPercentage = 0;
String CollectionPercentageStr = "";
double CurrentMonthSalesPercentage = 0;
String CurrentMonthSalesPercentageStr = "";
String LastMonthPercentageStr = "";
String CurrentQtrPercentageStr = "";
String YtdPercentageStr = "";
List<Map<String, dynamic>> collectionList = [];
List<CollectionList> collection = [];
List<Map<String, dynamic>> salesList = [];

List<SalesList> sales = [];
List<PODetailList> poDetailListMain = [];
bool noUserList = false;
bool halfPieLoaded = false;
DateTime? currentDate;
DateTime? currentMonthFromDate;
DateTime? lastMonthFromDate;
DateTime? lastMonthToDate;
DateTime? currentQuarterFromDate;
DateTime? currentQuarterToDate;
DateTime? fiscalYearStartDate;
int currentQuarter = 0;
DateTime? prevFiscalYearStartDate;
DateTime? prevFiscalYearEndDate;
DateTime? lastQuarterFromDate;
DateTime? lastQuarterToDate;
String financialYear = "";
String prevFinancialYear = "";
double selectedProduct = 0;
final TextEditingController customerController = TextEditingController();
String selectedCustomerName = "";
String selectedCustomerCode = "";

class MonthlySaleData {
  String saleMonth;
  double saleAmount;
  MonthlySaleData({required this.saleMonth, required this.saleAmount});
}

class ProductSale {
  String ProductIndex;
  String SaleMonth;
  String ProductName;
  double SaleValue;
  ProductSale({
    required this.ProductIndex,
    required this.SaleMonth,
    required this.ProductName,
    required this.SaleValue,
  });
  factory ProductSale.fromJson(Map<String, dynamic> json) {
    return ProductSale(
      ProductIndex: json['ProductIndex'],
      SaleMonth: json['SaleMonth'],
      ProductName: json['ProductName'],
      SaleValue: double.parse(json['SaleValue']),
    );
  }
}

class CustomerSalesPerformancePageState
    extends State<CustomerSalesPerformancePage> {
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
  List<Map<String, dynamic>> distributorList = [];
  List<Map<String, dynamic>> poDetailList = [];
  ScrollController customerSalesPerformancePageController = ScrollController();

  List<Distributor> convertDist(List<Map<String, dynamic>> distributorList) {
    return distributorList
        .map(
          (map) => Distributor(
            CustomerCode: map['CustomerCode']?.toString() ?? '',
            CustomerName: map['CustomerName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  Future<List<Distributor>> getDistributor(String search) async {
    List<Distributor> distList = convertDist(distributorList);
    List<Distributor> filteredList = distList
        .where(
          (element) => element.CustomerName.toLowerCase().startsWith(
            search.toLowerCase(),
          ),
        )
        .toList();

    return filteredList;
  }

  Future<void> _loadcustomer(
    String userId,
    String userJwtToken,
    String userMailID,
    String userName,
  ) async {
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserName': userName,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectcustomerbyuser';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        // int dataLength = data.length;
        if (status && responseJson["Data"].toString().isNotEmpty) {
          final List data = jsonDecode(response.body)["Data"];
          List<Map<String, dynamic>> newDistributorList = [];
          for (var item in data) {
            final dist = {
              "CustomerCode": item["CustomerCode"],
              "CustomerName": item["CustomerName"],
            };
            newDistributorList.add(dist);
          }
          setState(() {
            distributorList = newDistributorList;
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
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        final snackBar = SnackBar(
          content: Text('Customers not assigned for the user: $userName'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  var distributorKey = GlobalKey();

  SideTitles get _bottomTitles2 =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitles);

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  Widget getBottomTitles(double val, TitleMeta meta) {
    String text = '';
    MonthlySalesData monthlySalesData = monthlySalesList.monthlyData.elementAt(
      val.toInt(),
    );
    text = monthlySalesData.monthName;
    return Text(text.substring(0, 3));
  }

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

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
            '${text.substring(0, 5)}...',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    },
  );

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String leftDouble = "";
      leftDouble = formatAmount(value);
      return Text(leftDouble, style: const TextStyle(fontSize: 12));
    },
  );

  List<BarChartGroupData> _chartLastMonthGroups(
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
                  color: Colors.cyan.shade100,
                ),
                color: Colors.cyan,
                borderRadius: BorderRadius.zero,
                toY: sales.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _chartProductsSoldGroups(
    List<ProductwiseData> productwiseSalesData,
  ) {
    return productwiseSalesData
        .map(
          (sales) => BarChartGroupData(
            x: productwiseSalesData.indexOf(sales),
            barRods: [
              BarChartRodData(
                borderRadius: BorderRadius.zero,
                color: Colors.cyan,
                toY: sales.salesAmount,
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
    return ((maxValue ~/ 10000000) + 1) * 10000000;
  }

  double getProductMaxValue(ProductwiseSalesList productwiseSalesList) {
    double maxValue = 0.0;
    for (var productData in productwiseSalesList.productData) {
      maxValue = maxValue > productData.salesAmount
          ? maxValue
          : productData.salesAmount;
      maxValue = maxValue > productData.targetAmount
          ? maxValue
          : productData.targetAmount;
    }
    return ((maxValue ~/ 5000000) + 1) * 5000000;
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

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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

  int getLastTwoDigitsOfYear(DateTime date) {
    int year = date.year;
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

  Future<void> _loadMonthlySalesBarChartData() async {
    List<MonthlySalesData> monthlyDataList = [];
    int currentYear = DateTime.now().year;

    // Loop through fiscal months (April to March of next year)
    for (int i = 4; i <= 15; i++) {
      String monthName = getMonthName(i);
      double monthlyTarget = 0.00;
      double monthlySales = 0.00;

      // Get the three-month range for calculating targets
      DateTime prevThreeMthFromDate = (i <= 12)
          ? DateTime(currentDate!.year, i - 3, 1)
          : DateTime(currentYear, i - 12 - 3, 1);
      DateTime prevThreeMthToDate = (i <= 12)
          ? DateTime(currentDate!.year, i, 0)
          : addMonth(prevThreeMthFromDate, 3).add(const Duration(days: -1));

      // Get the month range for calculating sales
      Map<String, DateTime> monthDates = getMonthStartEndDates(i);

      // Filter sales data
      Iterable<SalesList> curMthSalesTarget = _filterSalesByDate(
        sales,
        prevThreeMthFromDate,
        prevThreeMthToDate,
        selectedCustomerCode,
      );

      Iterable<SalesList> monthlySalesList = _filterSalesByDate(
        sales,
        monthDates['start']!,
        monthDates['end']!,
        selectedCustomerCode,
      );

      // Calculate monthly target (average of three months)
      monthlyTarget = _calculateTotalSales(curMthSalesTarget) / 3;

      // Calculate monthly sales
      monthlySales = _calculateTotalSales(monthlySalesList);

      // Add data to the monthly sales list
      monthlyDataList.add(
        MonthlySalesData(
          monthName: monthName,
          salesAmount: monthlySales,
          salesTarget: double.parse(monthlyTarget.toStringAsFixed(2)),
        ),
      );
    }

    // Update the state or data model
    setState(() {
      monthlySalesList = MonthlySalesList(monthlyData: monthlyDataList);
    });
  }

  // Helper to filter sales data by date and customer code
  Iterable<SalesList> _filterSalesByDate(
    Iterable<SalesList> sales,
    DateTime startDate,
    DateTime endDate,
    String selectedCustomerCode,
  ) {
    return sales.where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      bool withinDateRange =
          invoiceDate.isAtLeast(startDate) && invoiceDate.isAtMost(endDate);

      if (selectedCustomerCode.isNotEmpty) {
        return withinDateRange && target.customerCode == selectedCustomerCode;
      }
      return withinDateRange;
    }).toSet();
  }

  // Helper to calculate total sales for a given sales list
  double _calculateTotalSales(Iterable<SalesList> salesList) {
    return salesList.fold(0.0, (sum, target) {
      double salesAmt = double.tryParse(target.rowTotal) ?? 0.0;
      if (target.invoiceType == "Sales Return") {
        salesAmt *= -1; // Negate for returns
      }
      return sum + salesAmt;
    });
  }

  void loadMonthlySalesBarChartDataFromPieChart(int piechartIndex) {
    LoadDates();
    List<MonthlySalesData> monthlyDataList = [];
    List<PrevYearMonthData> prevYearMonthDataList = [];
    prevYearMonthList = PrevYearMonthList(prevYearMonthData: []);

    String monthName = "";
    double monthlyTarget = 0.00;
    double monthlySales = 0.00;
    double sum = 0.00;
    if (piechartIndex == 1) {
      monthName = getMonthName(lastMonthFromDate!.month);
      DateTime? prevThreeMthFromDate = DateTime(
        currentDate!.year,
        currentDate!.month - 3,
        1,
      );
      DateTime? prevThreeMthToDate = DateTime(
        currentDate!.year,
        currentDate!.month,
        0,
      );
      sum = 0.00;
      var curMthSalesTarget = sales.where((target) {
        if (selectedCustomerCode != "") {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.invoiceDate);
          String customerCode = target.customerCode;
          return invoiceDate.isAtLeast(prevThreeMthFromDate) &&
              invoiceDate.isAtMost(prevThreeMthToDate) &&
              customerCode == selectedCustomerCode;
        } else {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.invoiceDate);
          return invoiceDate.isAtLeast(prevThreeMthFromDate) &&
              invoiceDate.isAtMost(prevThreeMthToDate);
        }
      });

      sum = 0;
      for (var target in curMthSalesTarget.toList()) {
        double salesAmt = 0;
        if (target.invoiceType != "Sales Return") {
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
        } else {
          salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
        }
        sum += salesAmt;
      }
      monthlyTarget = double.parse((sum / 3).toStringAsFixed(2));

      var lastMonthSales = sales.where((target) {
        if (selectedCustomerCode != "") {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.invoiceDate);
          String customerCode = target.customerCode;
          return invoiceDate.isAtLeast(lastMonthFromDate!) &&
              invoiceDate.isAtMost(lastMonthToDate!) &&
              customerCode == selectedCustomerCode;
        } else {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.invoiceDate);
          return invoiceDate.isAtLeast(lastMonthFromDate!) &&
              invoiceDate.isAtMost(lastMonthToDate!);
        }
      });

      for (var target in lastMonthSales.toList()) {
        monthlySales += double.tryParse(target.rowTotal) ?? 0;
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
      DateTime? fromDate = currentQuarterFromDate;
      DateTime? toDate = addMonth(fromDate!, 1).add(const Duration(days: -1));
      var lastQtrSalesTarget = sales.where((target) {
        if (selectedCustomerCode != "") {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.invoiceDate);
          String customerCode = target.customerCode;
          return invoiceDate.isAtLeast(lastQuarterFromDate!) &&
              invoiceDate.isAtMost(lastQuarterToDate!) &&
              customerCode == selectedCustomerCode;
        } else {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.invoiceDate);
          return invoiceDate.isAtLeast(lastQuarterFromDate!) &&
              invoiceDate.isAtMost(lastQuarterToDate!);
        }
      });

      monthlyTarget = 0;
      sum = 0;
      for (var target in lastQtrSalesTarget.toList()) {
        double salesAmt = 0;
        if (target.invoiceType != "Sales Return") {
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
        } else {
          salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
        }
        sum += salesAmt;
      }
      monthlyTarget = double.parse((sum / 3).toStringAsFixed(2));

      for (int i = 1; i <= 3; i++) {
        monthlySales = 0;
        var curQtrSales = sales.where((target) {
          if (selectedCustomerCode != "") {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.invoiceDate);
            String customerCode = target.customerCode;
            return invoiceDate.isAtLeast(fromDate!) &&
                invoiceDate.isAtMost(toDate!) &&
                customerCode == selectedCustomerCode;
          } else {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.invoiceDate);
            return invoiceDate.isAtLeast(fromDate!) &&
                invoiceDate.isAtMost(toDate!);
          }
        });

        for (var target in curQtrSales.toList()) {
          monthlySales += double.tryParse(target.rowTotal) ?? 0;
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
        fromDate = addMonth(fromDate!, 1);
        toDate = DateTime(fromDate.year, fromDate.month + 1, 0);
      }
    }
    monthlySales = 0;
    monthlyTarget = 0;
    monthlySalesList = MonthlySalesList(monthlyData: monthlyDataList);
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  Future<void> _loadMonthlyProductwiseSalesBarChartData(int monthIndex) async {
    List<ProductwiseData> productwiseDataList = [];
    DateTime startDate;
    DateTime endDate;

    // Determine start and end dates
    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
    } else if (monthIndex >= 4 && monthIndex <= 12) {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    } else {
      int currentYear = DateTime.now().year;
      startDate = DateTime(currentYear, monthIndex, 1);
      endDate = DateTime(currentYear, monthIndex + 1, 0);
    }

    // Filter sales data once based on date range and customer code
    var filteredSales = sales.where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      if (selectedCustomerCode.isNotEmpty) {
        return invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate) &&
            target.customerCode == selectedCustomerCode;
      }
      return invoiceDate.isAtLeast(startDate) && invoiceDate.isAtMost(endDate);
    });

    // Aggregate sales data by product code
    Map<String, ProductwiseData> salesByProduct = {};
    for (var sale in filteredSales) {
      double salesAmount = double.tryParse(sale.rowTotal) ?? 0.0;
      if (salesByProduct.containsKey(sale.code)) {
        salesByProduct[sale.code]!.salesAmount += salesAmount;
      } else {
        salesByProduct[sale.code] = ProductwiseData(
          productCode: sale.code,
          productName: sale.description,
          salesAmount: salesAmount,
          targetAmount: salesAmount, // Assuming target = sales
        );
      }
    }

    // Convert aggregated data to a list and sort
    productwiseDataList = salesByProduct.values.toList();
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    // Update the final product sales list
    productwiseSalesList = ProductwiseSalesList(
      productData: productwiseDataList,
    );
  }

  Future<void> _loadPODetails() async {
    int index = 0;
    int limit = 10000;
    List<PODetailList> salesList = [];

    final body = {
      'FromDate': formatDate(fiscalYearStartDate!),
      'ToDate': formatDate(currentDate!),
      "Index": index.toString(),
      "Limit": limit.toString(),
      "sapToken": DataManager.readSapToken(),
    };
    const apiUrl = '${ApiHelper.baseUrl}CRM_SOList';
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
          List<PODetailList> newSalesList =
              (responseJson['responseData'] as List)
                  .map((item) => PODetailList.fromJson(item))
                  .toList();

          salesList.addAll(newSalesList);

          setState(() {
            if (selectedCustomerCode == "") {
              poDetailListMain = salesList;
            } else {
              poDetailListMain = salesList
                  .where(
                    (element) => element.customerCode == selectedCustomerCode,
                  )
                  .toList();
            }
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
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        const snackBar = SnackBar(content: Text('SO list not found.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
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
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadSalesTarget() async {
    // Helper method to parse date
    DateTime parseDate(String date) => DateFormat('dd/MM/yyyy').parse(date);

    // Helper method to calculate sales sum
    double calculateTarget(Set<SalesList> targets) {
      return targets.fold(0, (sum, target) {
        double salesAmt = double.tryParse(target.rowTotal) ?? 0;
        return sum +
            (target.invoiceType == "Sales Return" ? -salesAmt : salesAmt);
      });
    }

    // Helper method to filter sales data
    Set<SalesList> filterSales(
      DateTime fromDate,
      DateTime toDate, {
      bool isLastQuarter = false,
    }) {
      return sales.where((target) {
        DateTime invoiceDate = parseDate(target.invoiceDate);
        bool isWithinRange =
            invoiceDate.isAtLeast(fromDate) && invoiceDate.isAtMost(toDate);

        if (selectedCustomerCode.isNotEmpty) {
          return isWithinRange && target.customerCode == selectedCustomerCode;
        }
        return isWithinRange;
      }).toSet();
    }

    // Previous three months' target
    DateTime prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var curMthSalesTarget = filterSales(
      prevThreethFromDate,
      prevThreeMthToDate,
    );
    SalesGoal = double.parse(
      (calculateTarget(curMthSalesTarget) / 3).toStringAsFixed(2),
    );
    SalesGoalStr = "${(SalesGoal / 100000).toStringAsFixed(2)} L";

    // Last month's target
    var lastMonthFromDate = addMonth(prevThreethFromDate, -1);
    var lastMonthToDate = addMonth(
      prevThreeMthToDate,
      -1,
    ).subtract(const Duration(days: 1));

    var lastMthSalesTarget = filterSales(lastMonthFromDate, lastMonthToDate);
    LastMonthTarget = double.parse(
      (calculateTarget(lastMthSalesTarget) / 3).toStringAsFixed(2),
    );
    LastMonthTargetStr = "${(LastMonthTarget / 100000).toStringAsFixed(2)} L";

    // Current quarter's target
    var currentQtrSalesTarget = filterSales(
      currentQuarterFromDate!,
      currentQuarterToDate!,
    );
    CurrentQtrTarget = calculateTarget(currentQtrSalesTarget);
    CurrentQtrTargetStr = "${(CurrentQtrTarget / 100000).toStringAsFixed(2)} L";

    // Year-to-date (YTD) target
    var ytdSalesTarget = filterSales(
      prevFiscalYearStartDate!,
      prevFiscalYearEndDate!,
    );
    double ytdSum = calculateTarget(ytdSalesTarget);

    int monthOffset = currentDate!.month <= 12 && currentDate!.month >= 4
        ? currentDate!.month - 3
        : currentDate!.month + 9;

    YtdTarget =
        double.tryParse(((ytdSum / 12) * monthOffset).toStringAsFixed(2)) ?? 0;
    YtdTargetStr = "${(YtdTarget / 100000).toStringAsFixed(2)} L";
  }

  Future<void> _loadSales(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;
    List<SalesList> salesList = [];
    int monthIndex = currentDate!.month;

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
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson["responseData"].toString().isNotEmpty) {
          List<SalesList> newSalesList = (responseJson['responseData'] as List)
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

    // Update Sales List and User-based Filtering
    setState(() {
      context
          .read<SalesListCustomerSalesPerformancePageProvider>()
          .updateSalesList(salesList);

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
      halfPieLoaded = true;
    });

    // Load Sales Targets
    await _loadSalesTarget();

    // Calculate Monthly, Quarterly, and Yearly Sales
    CurrentMonthSales = _calculateSales(
      sales,
      startDate: currentMonthFromDate!,
      endDate: currentDate!,
      selectedCustomerCode: selectedCustomerCode,
    );
    CurrentMonthSalesStr =
        "${(CurrentMonthSales / 100000).toStringAsFixed(2)} L";
    CurrentMonthSalesPercentage = (SalesGoal > 0)
        ? (CurrentMonthSales / SalesGoal) * 100
        : 0;
    CurrentMonthSalesPercentageStr =
        "${CurrentMonthSalesPercentage.clamp(0, 100).toStringAsFixed(2)} %";

    LastMonthSales = _calculateSales(
      sales,
      startDate: lastMonthFromDate!,
      endDate: lastMonthToDate!,
      selectedCustomerCode: selectedCustomerCode,
    );
    LastMonthSalesStr = "${(LastMonthSales / 100000).toStringAsFixed(2)} L";
    LastMonthPercentage = (LastMonthTarget > 0)
        ? (LastMonthSales / LastMonthTarget) * 100
        : 0;
    LastMonthPercentageStr =
        "${LastMonthPercentage.clamp(0, 100).toStringAsFixed(2)} %";

    CurrentQtrSales = _calculateSales(
      sales,
      startDate: currentQuarterFromDate!,
      endDate: currentQuarterToDate!,
      selectedCustomerCode: selectedCustomerCode,
    );
    CurrentQtrSalesStr = "${(CurrentQtrSales / 100000).toStringAsFixed(2)} L";
    CurrentQtrPercentage = (CurrentQtrTarget > 0)
        ? (CurrentQtrSales / CurrentQtrTarget) * 100
        : 0;
    CurrentQtrPercentageStr =
        "${CurrentQtrPercentage.clamp(0, 100).toStringAsFixed(2)} %";

    YtdSales = _calculateSales(
      sales,
      startDate: fiscalYearStartDate!,
      endDate: currentDate!,
      selectedCustomerCode: selectedCustomerCode,
    );
    YtdSalesStr = "${(YtdSales / 100000).toStringAsFixed(2)} L";
    YtdPercentage = (YtdTarget > 0) ? (YtdSales / YtdTarget) * 100 : 0;
    YtdPercentageStr = "${YtdPercentage.clamp(0, 100).toStringAsFixed(2)} %";
  }

  double _calculateSales(
    List<SalesList> sales, {
    required DateTime startDate,
    required DateTime endDate,
    String selectedCustomerCode = "",
  }) {
    double sum = 0;

    final filteredSales = sales.where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      bool withinDateRange =
          invoiceDate.isAtLeast(startDate) && invoiceDate.isAtMost(endDate);

      if (selectedCustomerCode.isNotEmpty) {
        return withinDateRange && target.customerCode == selectedCustomerCode;
      }
      return withinDateRange;
    });

    for (var target in filteredSales) {
      double salesAmt = double.tryParse(target.rowTotal) ?? 0;
      if (target.invoiceType == "Sales Return") {
        salesAmt *= -1;
      }
      sum += salesAmt;
    }

    return sum;
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userName = prefs.getString('userName') ?? '';
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;

    await _loadUserList(
      userId,
      userJwtToken,
      userMailID,
      int.tryParse(userLevel) ?? 0,
    );
    await _loadcustomer(userId, userJwtToken, userMailID, userName);
    await _loadSales(userName, userLevel);
    await _loadMonthlySalesBarChartData();
    showDrillDownChart = true;
    touchedYearGraph = true;
    showProductSaleChart = true;
    await _loadMonthlyProductwiseSalesBarChartData(0);
    await _loadPODetails();
    loadingComplete = true;
  }

  Future<void> loadDataWithFilter(String customerCode) async {
    final prefs = await SharedPreferences.getInstance();
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    LoadDates();
    await _loadMonthlySalesBarChartData();
    showDrillDownChart = true;
    touchedYearGraph = true;
    showProductSaleChart = true;
    await _loadMonthlyProductwiseSalesBarChartData(0);
    await _loadPODetails();
    loadingComplete = true;
  }

  @override
  void initState() {
    super.initState();
    selectedCustomerCode = widget.customerCode != "" ? widget.customerCode : "";
    loadingComplete = false;
    LoadDates();
    if (isUserLoggedIn && isCustomerDashboardStart) {
      loadDataFuture = loadData("");
    }
    showDrillDownChart = true;
    showProductSaleChart = false;
    touchedYearGraph = true;
  }

  @override
  void dispose() {
    selectedCustomerCode = "";
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      deviceOrientation = "Portrait";
    } else {
      deviceOrientation = "Landscape";
    }
    final screenHeight = MediaQuery.of(context).size.height;
    double containerDropDownHeight = 0;
    double containerHeight = 0;
    if (deviceOrientation == "Portrait") {
      containerDropDownHeight = screenHeight * 0.06;
      containerHeight = screenHeight * 0.06;
    } else {
      containerDropDownHeight = screenHeight * 0.12;
    }
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton(
            child: const Icon(Icons.filter_alt_outlined),
            onSelected: (value) {},
            itemBuilder: (BuildContext bc) {
              return [
                PopupMenuItem(
                  onTap: () {
                    setState(() {
                      prevYearMonthList = PrevYearMonthList(
                        prevYearMonthData: [],
                      );
                      showDrillDownChart = false;
                      showProductSaleChart = false;
                      lastThreeMonthChartFunc = false;
                      lastMonthChartFunc = false;
                      touchedMonthGoals = false;
                      touchedQuarterGoals = false;
                      touchedYTDGoals = false;
                      selectedCustomerCode = "";
                      _loadMonthlySalesBarChartData();
                      showDrillDownChart = true;
                      touchedYearGraph = true;
                      showProductSaleChart = true;
                      touchedMonthIndex = 0;
                      customerController.clear();
                      _loadMonthlyProductwiseSalesBarChartData(0);
                      _loadPODetails();
                    });
                  },
                  child: const Row(children: [Text("Remove Filter?")]),
                ),
              ];
            },
          ),
          const SizedBox(width: 20),
        ],
        automaticallyImplyLeading: false,
        title: Text(
          showDrillDownChart
              ? touchedMonthIndex != 0
                    ? 'Product Sales for the month of ${getMonthName(touchedMonthIndex)}'
                    : 'Monthly Sales'
              : 'Monthly Sales',
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: loadingComplete == true
          ? SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: customerSalesPerformancePageController,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: deviceOrientation == "Portrait"
                          ? containerHeight
                          : containerDropDownHeight / 1.5,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: AsyncAutocomplete<Distributor>(
                              onChanged: (s) {
                                setState(() {
                                  customerController.text == s;
                                });
                              },
                              onSaved: (s) {
                                setState(() {
                                  customerController.text == s;
                                });
                              },
                              maxListHeight: deviceOrientation == "Portrait"
                                  ? 370
                                  : 220,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.only(
                                  left: 0,
                                  right: 30,
                                  top: 0,
                                  bottom: 0,
                                ),
                                border: UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                hintText: 'Account Name',
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF8F8F8F),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors
                                        .blue, // Set your desired focus color
                                  ),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                              ),
                              controller: customerController,
                              inputKey: distributorKey,
                              onTapItem: (Distributor distributor) async {
                                setState(() {
                                  customerController.text =
                                      distributor.CustomerName;
                                  var customer = distributorList.firstWhere(
                                    (map) =>
                                        map['CustomerName'] ==
                                        distributor.CustomerName,
                                  );
                                  selectedCustomerCode =
                                      customer['CustomerCode'].toString();
                                  selectedCustomerName =
                                      distributor.CustomerName;
                                  loadDataWithFilter(selectedCustomerCode);
                                });
                              },
                              suggestionBuilder: (data) =>
                                  ListTile(title: Text(data.CustomerName)),
                              asyncSuggestions: (searchValue) =>
                                  getDistributor(searchValue),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: -1,
                            bottom: 2,
                            child: Visibility(
                              child: SizedBox(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCustomerCode = "";
                                      selectedCustomerName = "";
                                      customerController.clear();
                                    });
                                  },
                                  child: customerController.text == ""
                                      ? Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.transparent,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.only(
                                              top: 14,
                                              right: 2,
                                            ),
                                            child: Icon(
                                              Icons.search,
                                              color: Color(0xff2ca9df),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.transparent,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.only(
                                              top: 14,
                                              right: 2,
                                            ),
                                            child: Icon(
                                              Icons.cancel_outlined,
                                              color: Color(0xff2ca9df),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // nodes.isNotEmpty
                  //     ? Visibility(
                  //         visible: noUserList,
                  //         child: SizedBox(
                  //           height: 125,
                  //           child: TreeView<MyNode>(
                  //             treeController: treeController,
                  //             nodeBuilder: (BuildContext context,
                  //                 TreeEntry<MyNode> entry) {
                  //               return MyTreeTile(
                  //                 key: ValueKey(entry.node),
                  //                 entry: entry,
                  //                 onTap: () {
                  //                   treeController.toggleExpansion(entry.node);
                  //                 },
                  //               );
                  //             },
                  //           ),
                  //         ),
                  //       )
                  //     : const Center(child: CircularProgressIndicator()),
                  SizedBox(
                    height: screenHeight / 2.5,
                    child: Stack(
                      children: [
                        Center(
                          child: CircularPercentIndicator(
                            arcType: ArcType.HALF,
                            radius: 120.0,
                            lineWidth: 50.0,
                            animation: true,
                            percent: CurrentMonthSalesPercentage / 100,
                            center: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 70.0),
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
                          top: screenHeight / 4,
                          left: screenHeight / 35,
                          child: SizedBox(
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4.0,
                                    right: 4.0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        loadMonthlySalesBarChartDataFromPieChart(
                                          1,
                                        );
                                        _chartLastMonthGroups(
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
                                    child: CircularPercentIndicator(
                                      arcType: ArcType.HALF,
                                      radius: 55.0,
                                      lineWidth: 20.0,
                                      animation: true,
                                      percent: LastMonthPercentage / 100,
                                      center: Column(
                                        children: [
                                          const SizedBox(height: 30),
                                          Text(
                                            LastMonthPercentageStr,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: touchedMonthGoals
                                                  ? 13.0
                                                  : 12.0,
                                              color: touchedMonthGoals
                                                  ? Colors.cyan
                                                  : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            LastMonthSalesStr,
                                            style: TextStyle(
                                              fontSize: touchedMonthGoals
                                                  ? 11.0
                                                  : 10.0,
                                              color: touchedMonthGoals
                                                  ? Colors.cyan
                                                  : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Center(
                                            child: Text(
                                              "${getMonthName(currentDate!.month - 1)} Sales \n($LastMonthTargetStr)",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: touchedMonthGoals
                                                    ? 11.0
                                                    : 10.0,
                                                color: touchedMonthGoals
                                                    ? Colors.cyan
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      curve: Curves.linear,
                                      circularStrokeCap: CircularStrokeCap.butt,
                                      progressColor: Colors.red,
                                      arcBackgroundColor: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        lastMonthChartFunc = false;
                                        lastThreeMonthChartFunc = true;
                                        loadMonthlySalesBarChartDataFromPieChart(
                                          2,
                                        );
                                        _chartLastMonthGroups(
                                          monthlySalesList.monthlyData,
                                        );
                                        showProductSaleChart = false;
                                        showDrillDownChart = false;

                                        touchedMonthGoals = false;
                                        touchedQuarterGoals = true;
                                        touchedYTDGoals = false;
                                      });
                                    },
                                    child: CircularPercentIndicator(
                                      arcType: ArcType.HALF,
                                      radius: 55.0,
                                      lineWidth: 20.0,
                                      animation: true,
                                      percent: CurrentQtrPercentage / 100,
                                      center: Column(
                                        children: [
                                          const SizedBox(height: 30),
                                          Text(
                                            CurrentQtrPercentageStr,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: touchedQuarterGoals
                                                  ? 13.0
                                                  : 12.0,
                                              color: touchedQuarterGoals
                                                  ? Colors.cyan
                                                  : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            CurrentQtrSalesStr,
                                            style: TextStyle(
                                              fontSize: touchedQuarterGoals
                                                  ? 11.0
                                                  : 10.0,
                                              color: touchedQuarterGoals
                                                  ? Colors.cyan
                                                  : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "Q$currentQuarter Sales \n($CurrentQtrTargetStr)",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: touchedQuarterGoals
                                                  ? 11.0
                                                  : 10.0,
                                              color: touchedQuarterGoals
                                                  ? Colors.cyan
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      curve: Curves.linear,
                                      circularStrokeCap: CircularStrokeCap.butt,
                                      progressColor: Colors.orange,
                                      arcBackgroundColor: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _loadMonthlySalesBarChartData();
                                        _chartLastMonthGroups(
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
                                    child: CircularPercentIndicator(
                                      arcType: ArcType.HALF,
                                      radius: 55.0,
                                      lineWidth: 20.0,
                                      animation: true,
                                      percent: YtdPercentage / 100,
                                      center: Column(
                                        children: [
                                          const SizedBox(height: 30),
                                          Text(
                                            YtdPercentageStr,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: touchedYTDGoals
                                                  ? 13.0
                                                  : 12.0,
                                              color: touchedYTDGoals
                                                  ? Colors.cyan
                                                  : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            YtdSalesStr,
                                            style: TextStyle(
                                              fontSize: touchedYTDGoals
                                                  ? 11.0
                                                  : 10.0,
                                              color: touchedYTDGoals
                                                  ? Colors.cyan
                                                  : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "YTD \n($YtdTargetStr)",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: touchedYTDGoals
                                                  ? 11.0
                                                  : 10.0,
                                              color: touchedYTDGoals
                                                  ? Colors.cyan
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      curve: Curves.linear,
                                      circularStrokeCap: CircularStrokeCap.butt,
                                      progressColor: Colors.green,
                                      arcBackgroundColor: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, right: 16.0),
                    child: Divider(thickness: 2),
                  ),
                  const SizedBox(height: 15),
                  Visibility(
                    visible: productwiseSalesList.productData.isNotEmpty,
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 15),
                            Text("Sales Goal / Actual"),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildMonthlySalesChart(),
                        ),
                        const SizedBox(height: 15),
                        const Padding(
                          padding: EdgeInsets.only(left: 16.0, right: 16.0),
                          child: Divider(thickness: 2),
                        ),
                      ],
                    ),
                  ),

                  Visibility(
                    visible: productwiseSalesList.productData.isNotEmpty,
                    child: Column(
                      children: [
                        const SizedBox(height: 15),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 15),
                            Text("Top Selling Products"),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildProductSalesChart(),
                        ),
                        const SizedBox(height: 15),
                        const Padding(
                          padding: EdgeInsets.only(left: 16.0, right: 16.0),
                          child: Divider(thickness: 2),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [SizedBox(width: 15), Text("PO Details")],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 400,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Container(
                                margin: const EdgeInsets.all(20),
                                child: Table(
                                  defaultColumnWidth: const FixedColumnWidth(
                                    150.0,
                                  ),
                                  border: TableBorder.all(
                                    color: Colors.black,
                                    style: BorderStyle.solid,
                                    width: 0.5,
                                  ),
                                  children: [
                                    const TableRow(
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              'Date',
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Value',
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Status',
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Remarks',
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    for (var data in poDetailListMain)
                                      TableRow(
                                        children: [
                                          Column(children: [Text(data.soDate)]),
                                          Column(
                                            children: [Text(data.orderValue)],
                                          ),
                                          Column(
                                            children: [Text(data.soStatus)],
                                          ),
                                          Column(children: [Text(data.remark)]),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  void _scrollDown() {
    customerSalesPerformancePageController.animateTo(
      customerSalesPerformancePageController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  Widget _buildMonthlySalesChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    double barChartWidth = 0.0;
    int length = monthlySalesList.monthlyData.length;
    length > 6
        ? barChartWidth = screenWidth + (35 * length)
        : barChartWidth = screenWidth;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 400,
        width: barChartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(monthlySalesList),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              // leftTitles: const AxisTitles(
              //   sideTitles: SideTitles(showTitles: true, reservedSize: 60),
              // ),
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
            barGroups: _chartLastMonthGroups(monthlySalesList.monthlyData),
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
                      touchedMonthIndex = touchedMonthIndex == 0
                          ? months.indexOf(touchedMonth.substring(0, 3)) + 1
                          : 0;
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      _loadMonthlyProductwiseSalesBarChartData(
                        touchedMonthIndex,
                      );
                      touchedYearGraph = true;
                    }
                  });
                  if (showProductSaleChart != true) {
                    await Future.delayed(const Duration(milliseconds: 50));
                    _scrollDown();
                  }
                }
                setState(() {});
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '',
                    const TextStyle(color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(
                        text: "Target :${rodData.backDrawRodData.toY} ",
                        style: TextStyle(
                          color: Colors.cyan.shade100, //widget.touchedBarColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: "Achieved: ${rodData.toY}",
                        style: const TextStyle(
                          color: Colors.cyan, //widget.touchedBarColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
                getTooltipColor: (group) => Colors.black87,
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

  Widget _buildProductSalesChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    double barChartWidth = 0.0;
    int length = productwiseSalesList.productData.length;
    length > 6
        ? barChartWidth = screenWidth + (50 * length)
        : barChartWidth = screenWidth;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 400,
        width: barChartWidth,
        child: BarChart(
          BarChartData(
            maxY: getProductMaxValue(productwiseSalesList),
            barTouchData: BarTouchData(
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showProductSaleChart = true;
                      touchedYearGraph = true;
                    }
                  });
                  if (showProductSaleChart != true) {
                    await Future.delayed(const Duration(milliseconds: 50));
                    _scrollDown();
                  }
                }
              },
              allowTouchBarBackDraw: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    "Product Code: ${productwiseSalesList.productData[grpIndex].productCode}\n"
                    " Product Name: ${productwiseSalesList.productData[grpIndex].productName}\n"
                    " Sales Amount: ${rodData.toY}",
                    const TextStyle(color: Colors.black),
                  );
                },
                getTooltipColor: (group) => Colors.grey,
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
            barGroups: _chartProductsSoldGroups(
              productwiseSalesList.productData,
            ),
          ),
        ),
      ),
    );
  }
}

class PieChartSample2 extends StatefulWidget {
  const PieChartSample2({super.key});

  @override
  State<StatefulWidget> createState() => PieChart2State();
}

class PieChart2State extends State {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Row(
        children: <Widget>[
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 80,
                  startDegreeOffset: 180,
                  sections: showingSections(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(3, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 80.0 : 70.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.red,
            value: 40,
            title: '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: shadows,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Colors.grey.shade200,
            value: 10,
            title: '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: shadows,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: Colors.transparent,
            value: 50,
            title: '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: shadows,
            ),
          );
        default:
          throw Error();
      }
    });
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
