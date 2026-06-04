// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/login_screen.dart';
import '../../../api_helper.dart';
import '../../../classes/dashBoard.dart';
import '../../../classes/dataManager.dart';
import '../../../classes/globals.dart';
import '../../../classes/leads.dart';
import '../../../notificationService.dart';
import '../dashboard_card_ui.dart';

import '../ReportService.dart';

final reportService = ReportService();

class ProductMarginReport extends StatefulWidget {
  const ProductMarginReport({super.key});

  @override
  State<ProductMarginReport> createState() => _ProductMarginReportState();
}

late Future<void> loadDataFuture;
List<Users> usersList = [];
String UserLevel = "0";
List<SubGroupMarginTotal> itemSubGroupGraph = [];
SubGroupMarginTotalList itemSubGroupGraphList = SubGroupMarginTotalList(
  data: [],
);

class SubGroupMarginTotalList {
  final List<SubGroupMarginTotal> data;
  SubGroupMarginTotalList({required this.data});
}

class SubGroupMarginTotal {
  final String itemSubGroup;
  final double totalMarginAmount;
  final double marginPercent;

  SubGroupMarginTotal({
    required this.itemSubGroup,
    required this.totalMarginAmount,
    required this.marginPercent,
  });

  @override
  String toString() =>
      'SubGroup: $itemSubGroup, TotalMargin: ${totalMarginAmount.toStringAsFixed(2)}, '
      'Pct: ${marginPercent.toStringAsFixed(2)}%';
}

List<Users> usersListForFilter = [];
AllReceivablesFinanceList allReceivablesFinanceList = AllReceivablesFinanceList(
  agingData: [],
);
ReceivablesFinanceList receivablesFinanceList = ReceivablesFinanceList(
  agingData: [],
);
AdvanceFromCustomersList advanceCustomerList = AdvanceFromCustomersList(
  agingData: [],
);
CustomerAnalysisFinanceList customerAnalysisFinanceList =
    CustomerAnalysisFinanceList(customerData: []);
ReceivablesCategoryList receivablesCategoryList = ReceivablesCategoryList(
  categoryData: [],
);
TsmwiseCollectionList tsmwiseCollectionList = TsmwiseCollectionList(
  tsmwiseData: [],
);
AsmwiseCollectionList asmwiseCollectionList = AsmwiseCollectionList(
  asmwiseData: [],
);
RsmwiseCollectionList rsmwiseCollectionList = RsmwiseCollectionList(
  rsmwiseData: [],
);

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
int currentQuarter = 0;
bool chartDataLoadedProductMargin = false;

String touchedGroup = "";
String touchedItem = "";
double selectedChart = 0;

int selectedCheckbox = 1;

List<String> selectedSalesData = [];

final List<String> categories = ['Dates'];

List<String> listOfRSM = [];
List<String> listOfASM = [];
List<String> listOfTSM = [];

double sumOfCustomerCategoryWise = 0;

Map<String, Map<String, bool>> allCategoriesState = {};

bool fromFilter = false;

class ProductWiseMarginProvider with ChangeNotifier {
  List<SalesList> _salesList = [];
  List<SalesList> get salesList => _salesList;
  void updateSalesList(List<SalesList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class ProductWiseMarginItemCostProvider with ChangeNotifier {
  List<ItemCostList> _itemCostList = [];
  List<ItemCostList> get itemCostList => _itemCostList;
  void updateItemCostList(List<ItemCostList> newCostList) {
    _itemCostList = newCostList;
    notifyListeners();
  }
}

List<SalesList> sales = [];
List<SalesList> salesTemp = [];
List<ItemCostList> itemCostList = [];
YTDSalesList ytdSalesList = YTDSalesList(ytdData: []);
ProductMarginList productMarginList = ProductMarginList(productMarginData: []);
ProductMarginList productMarginListGraph = ProductMarginList(
  productMarginData: [],
);
bool YtdSalesBarChartData = false;

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

class _ProductMarginReportState extends State<ProductMarginReport> {
  bool showDrillDownChart = false;

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

  double roundUpTo50Lakhs(double value) {
    const step = 500; // 50 lakhs
    return (value / step).ceil() * step.toDouble();
  }

  double roundDownTo50Lakhs(double value) {
    const step = 500;
    return (value / step).floor() * step.toDouble();
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

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
        message: "Failed to load user list.",
      );
    }
  }

  Future<void> _loadSales(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 5000;
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
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          final data = responseJson['responseData'] as List?;

          if (data != null && data.isNotEmpty) {
            List<SalesList> newSalesList = data
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

      final filteredSales = salesList
          .where((test) => test.invoiceType == "Sales")
          .toList();
      if (!mounted) return;
      setState(() {
        context.read<ProductWiseMarginProvider>().updateSalesList(salesList);
        sales = filteredSales;
        salesTemp = filteredSales;
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error loading sales data.",
      );
    }
  }

  Future<void> _loadItemCost(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<ItemCostList> tmpItemList = [];
    try {
      do {
        var body = {"Index": index.toString(), "Limit": limit.toString()};
        const apiUrl = '${ApiHelper.baseUrl}BicxoItemCostList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          final data = responseJson['responseData'] as List?;

          if (data != null && data.isNotEmpty) {
            List<ItemCostList> newItemCostList = data
                .map((item) => ItemCostList.fromJson(item))
                .toList();

            tmpItemList.addAll(newItemCostList);
            fetchedCount = newItemCostList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      if (!mounted) return;

      setState(() {
        context.read<ProductWiseMarginItemCostProvider>().updateItemCostList(
          tmpItemList,
        );
        itemCostList = tmpItemList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error loading item cost data.",
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
    await _loadUserListForFilter(
      userId,
      userJwtToken,
      userMailID,
      int.tryParse(userLevel) ?? 0,
    );
    await _loadSales(userName, userLevel);
    await _loadItemCost(userName, userLevel);
    await _loadYtdSalesBarChartData("", "");
    if (!mounted) return;
    setState(() {
      chartDataLoadedProductMargin = true;
    });
  }

  void clearVariables() {
    setState(() {
      chartDataLoadedProductMargin = false;
      receivablesFinanceList = ReceivablesFinanceList(agingData: []);
      allReceivablesFinanceList = AllReceivablesFinanceList(agingData: []);
      advanceCustomerList = AdvanceFromCustomersList(agingData: []);
      customerAnalysisFinanceList = CustomerAnalysisFinanceList(
        customerData: [],
      );
      tsmwiseCollectionList = TsmwiseCollectionList(tsmwiseData: []);
      asmwiseCollectionList = AsmwiseCollectionList(asmwiseData: []);
      rsmwiseCollectionList = RsmwiseCollectionList(rsmwiseData: []);
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoadedProductMargin = false;
      receivablesFinanceList = ReceivablesFinanceList(agingData: []);
      advanceCustomerList = AdvanceFromCustomersList(agingData: []);
      customerAnalysisFinanceList = CustomerAnalysisFinanceList(
        customerData: [],
      );
      tsmwiseCollectionList = TsmwiseCollectionList(tsmwiseData: []);
      asmwiseCollectionList = AsmwiseCollectionList(asmwiseData: []);
      rsmwiseCollectionList = RsmwiseCollectionList(rsmwiseData: []);
    });
  }

  Future<void> _dateFilterTarget() async {
    setState(() {
      context.read<ProductWiseMarginProvider>().updateSalesList(sales);

      sales = sales.where((target) {
        DateTime dueon = target.invoiceDate;
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();
    });
  }

  Future<void> filterDateFunction() async {
    sales = salesTemp;
    _dateFilterTarget();
    await _loadYtdSalesBarChartData("", "");

    setState(() {});
    chartDataLoadedProductMargin = true;
  }

  Future<void> removeFilter() async {
    setState(() {
      chartDataLoadedProductMargin = false;
      clearVariables();
      LoadDates();
      allCategoriesState.forEach((category, options) {
        options.updateAll((key, value) => false);
      });
      allCategoriesState.clear();
      loadData("");
    });
  }

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  SideTitles get _leftProductTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String leftDouble = "";
      leftDouble = value.toStringAsFixed(0);
      return Text(leftDouble, style: const TextStyle(fontSize: 12));
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
      List<ProductMarginData> mData = productMarginList.productMarginData;
      text = mData.elementAt(value.toInt()).itemDescription;
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

  SideTitles get _bottomTitlesItemSubGroup => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<SubGroupMarginTotal> mData = itemSubGroupGraphList.data;
      text = mData.elementAt(value.toInt()).itemSubGroup;
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

  List<BarChartGroupData> _itemWiseChartData(List<ProductMarginData> data) {
    return List.generate(
      data.length,
      (index) => BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            color: const Color(0xFF2CA9DF),
            borderRadius: BorderRadius.zero,
            toY: data[index].marginPercent,
            width: 30,
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _itemSubGroupChartData(
    List<SubGroupMarginTotal> data,
  ) {
    return List.generate(
      data.length,
      (index) => BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            color: const Color(0xFF2CA9DF),
            borderRadius: BorderRadius.zero,
            toY: data[index].marginPercent,
            width: 30,
          ),
        ],
      ),
    );
  }

  String getSelectedFiltersText(
    Map<String, Map<String, bool>> allCategoriesState,
  ) {
    List<String> selectedFilters = [];
    allCategoriesState.forEach((category, options) {
      options.forEach((option, isSelected) {
        if (isSelected) {
          // If you want to include the category as well, you could do:
          // selectedFilters.add('$category: $option');
          selectedFilters.add(option);
        }
      });
    });
    return selectedFilters.join(', ');
  }

  Future<void> _loadYtdSalesBarChartData(
    String? itemGroup,
    String? item,
  ) async {
    List<ProductMarginData> ytdSalesDataList = [];

    // 1. Convert itemCostList to Map (O(1) lookup instead of O(n))
    final Map<String, double> itemCostMap = {
      for (var c in itemCostList)
        c.itemCode: double.tryParse(c.itemCost) ?? 0.0,
    };

    // 2. Group sales by item
    final Map<String, List<SalesList>> salesByItem = {};
    for (var sale in sales) {
      salesByItem.putIfAbsent(sale.code, () => []).add(sale);
    }

    // 3. Process each item
    for (var entry in salesByItem.entries) {
      final itemCode = entry.key;
      final itemSales = entry.value;
      final firstItemSale = itemSales.first;

      final double bomCost = itemCostMap[itemCode] ?? 0.0;

      double totalQty = 0.0;
      double totalValue = 0.0;

      // 4. Single loop instead of 12-month nested loop
      for (var sale in itemSales) {
        double rowTotal = double.tryParse(sale.rowTotal) ?? 0.0;
        double quantity = double.tryParse(sale.quantity) ?? 0.0;

        if (sale.invoiceType == "Sales Return") {
          rowTotal *= -1;
          quantity *= -1;
        }

        totalValue += rowTotal;
        totalQty += quantity;
      }

      if (totalValue != 0 && totalQty != 0) {
        final avgSellingPrice = totalValue / totalQty;
        final perUnitMargin = avgSellingPrice - bomCost;
        final totalMargin = perUnitMargin * totalQty;
        final marginPct = (avgSellingPrice > 0)
            ? (perUnitMargin / avgSellingPrice) * 100
            : 0.0;

        ytdSalesDataList.add(
          ProductMarginData(
            itemNo: firstItemSale.code,
            itemDescription: firstItemSale.description,
            itemSubGroup: firstItemSale.itemSubGroup,
            quantity: totalQty.toStringAsFixed(2),
            saleAmt: totalValue.toStringAsFixed(2),
            avgSellingPrice: avgSellingPrice.toStringAsFixed(2),
            bomCost: bomCost.toStringAsFixed(2),
            perUnitMarginAmount: perUnitMargin.toStringAsFixed(2),
            totalMarginAmount: totalMargin.toStringAsFixed(2),
            marginPercent: marginPct,
          ),
        );
      }
    }

    // 5. Clean + filter
    ytdSalesDataList.removeWhere((d) => d.itemSubGroup.isEmpty);

    List<ProductMarginData> filteredData = ytdSalesDataList;

    if (itemGroup != null && itemGroup.isNotEmpty) {
      filteredData = filteredData
          .where((d) => d.itemSubGroup == itemGroup)
          .toList();
    }

    if (item != null && item.isNotEmpty) {
      filteredData = filteredData
          .where((d) => d.itemDescription.contains(item))
          .toList();
    }

    // 6. Sort once
    filteredData.sort((a, b) => b.marginPercent.compareTo(a.marginPercent));

    // 7. Pre-calc subgroup totals (single pass)
    double overallTotal = 0.0;
    final Map<String, double> subgroupSums = {};

    for (var d in filteredData) {
      final m = double.tryParse(d.totalMarginAmount) ?? 0.0;
      overallTotal += m;
      subgroupSums.update(d.itemSubGroup, (ex) => ex + m, ifAbsent: () => m);
    }

    final subgroupList = subgroupSums.entries.map((e) {
      final pct = overallTotal > 0 ? (e.value / overallTotal) * 100 : 0.0;
      return SubGroupMarginTotal(
        itemSubGroup: e.key,
        totalMarginAmount: e.value,
        marginPercent: pct,
      );
    }).toList()..sort((a, b) => b.marginPercent.compareTo(a.marginPercent));

    // 8. Final UI update
    if (!mounted) return;

    setState(() {
      productMarginList = ProductMarginList(productMarginData: filteredData);
      productMarginListGraph = ProductMarginList(
        productMarginData: filteredData,
      );

      itemSubGroupGraph = subgroupList;
      itemSubGroupGraphList = SubGroupMarginTotalList(data: subgroupList);

      YtdSalesBarChartData = true;
    });
  }

  Future<void> generateSalesAnalysisYTDExcel() async {
    productMarginList.productMarginData.removeWhere(
      (item) => double.parse(item.quantity) < 0,
    );
    await reportService.generateExcel(
      sheetName: 'ProductMarginSales',
      headers: [
        'Item No.',
        'Item Description',
        'Item Sub Group',
        'Quantity',
        'Sales Amt',
        'Avg Selling Price',
        'BOMCost',
        'Per Unit Margin Amount',
        'Total Margin Amount',
        'Margin %',
      ],
      rows: productMarginList.productMarginData
          .map(
            (e) => [
              e.itemNo,
              e.itemDescription,
              e.itemSubGroup,
              e.quantity,
              e.saleAmt,
              e.avgSellingPrice,
              e.bomCost,
              e.perUnitMarginAmount,
              e.totalMarginAmount,
              e.marginPercent.toStringAsFixed(0),
            ],
          )
          .toList(),
      fileName: 'product_margin_sales_analysis.xlsx',
      amountColumns: [4, 5, 6, 7, 8, 9],
      addTotalRow: true,
      reportTitle: 'Finance - Product Margin Sales Analysis',
    );
    setState(() {
      YtdSalesBarChartData = true;
    });
  }

  Future<void> generateItemGroupWise() async {
    await reportService.generateExcel(
      sheetName: 'ProductMarginItemGroup',
      headers: ['Name', 'Margin Percentage', 'Total Margin Amount'],
      rows: itemSubGroupGraphList.data
          .map(
            (e) => [
              e.itemSubGroup,
              e.totalMarginAmount,
              e.marginPercent.toStringAsFixed(0),
            ],
          )
          .toList(),
      fileName: 'product_margin_itemgroup_analysis.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Finance - Product Margin Item Group Analysis',
    );

    setState(() {
      YtdSalesBarChartData = true;
    });
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  Future<void> loadDataWithFilter(
    String? touchedMonthGroup,
    String? touchedItem,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    _loadYtdSalesBarChartData(touchedMonthGroup, touchedItem);
    chartDataLoadedProductMargin = true;
  }

  @override
  void initState() {
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }

    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _itemWiseHorizontalController.dispose();
    _itemGroupHorizontalController.dispose();
    super.dispose();
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _itemWiseHorizontalController = ScrollController();
  final ScrollController _itemGroupHorizontalController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return chartDataLoadedProductMargin == true
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
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'Product Margin Report - Item Wise',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateSalesAnalysisYTDExcel();
                        },
                        child: const Text('Download Excel'),
                      ),
                    ],
                    child: _itemWise(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'Product Margin Report - Item Group Wise',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateItemGroupWise();
                        },
                        child: const Text('Download Excel'),
                      ),
                    ],
                    child: _itemSubGroupWise(),
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
          loadDataFuture = removeFilter();
        });
      }
    });
  }

  Widget _itemWise() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = productMarginListGraph.productMarginData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }

    final amounts = productMarginListGraph.productMarginData
        .map((e) => e.marginPercent)
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
    return FinanceHorizontalChartScroll(
      controller: _itemWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
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
                  sideTitles: _leftProductTitles,
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
              barGroups: _itemWiseChartData(
                productMarginListGraph.productMarginData,
              ),
              barTouchData: BarTouchData(
                // enabled: false,
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedItem = touchedItem == ""
                            ? productMarginListGraph
                                  .productMarginData[barTouchResponse
                                      .spot!
                                      .spot
                                      .x
                                      .toInt()]
                                  .itemDescription
                            : "";
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showDrillDownChart = true;
                        loadDataWithFilter(touchedGroup, touchedItem);
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
                      '${productMarginListGraph.productMarginData[grpIndex].itemDescription}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              'Margin Percentage: ${productMarginListGraph.productMarginData[grpIndex].marginPercent.toStringAsFixed(0)}\n',
                          style: const TextStyle(
                            color: Color(0xFF2CA9DF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              'Total Margin Amount: ${formatAmount(double.parse(productMarginListGraph.productMarginData[grpIndex].totalMarginAmount))}\n',
                          style: const TextStyle(
                            color: Color(0xFF2CA9DF),
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
    );
  }

  Widget _itemSubGroupWise() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemSubGroupGraphList.data.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? itemSubGroupGraphList.data
              .map((data) => data.marginPercent)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _itemGroupHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxAmount),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftProductTitles,
                  axisNameSize: 14,
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                bottomTitles: AxisTitles(
                  sideTitles: _bottomTitlesItemSubGroup,
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
              barGroups: _itemSubGroupChartData(itemSubGroupGraphList.data),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedGroup = touchedGroup == ""
                            ? itemSubGroupGraphList
                                  .data[barTouchResponse.spot!.spot.x.toInt()]
                                  .itemSubGroup
                            : "";
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showDrillDownChart = true;
                        loadDataWithFilter(touchedGroup, touchedItem);
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
                      '${itemSubGroupGraphList.data[grpIndex].itemSubGroup}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              'Margin Percentage: ${itemSubGroupGraphList.data[grpIndex].marginPercent.toStringAsFixed(0)}\n',
                          style: const TextStyle(
                            color: Color(0xFF2CA9DF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              'Total Margin Amount: ${formatAmount(itemSubGroupGraphList.data[grpIndex].totalMarginAmount)}\n',
                          style: const TextStyle(
                            color: Color(0xFF2CA9DF),
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
    );
  }
}
