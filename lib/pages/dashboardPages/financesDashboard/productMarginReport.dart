// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/login_screen.dart';
import '../../../api_helper.dart';
import '../../../classes/dashBoard.dart';
import '../../../classes/dataManager.dart';
import '../../../classes/globals.dart';
import '../../../classes/leads.dart';
import 'package:path_provider/path_provider.dart';

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';

class ProductMarginReport extends StatefulWidget {
  const ProductMarginReport({super.key});

  @override
  State<ProductMarginReport> createState() => _ProductMarginReportState();
}

late Future<void> loadDataFuture;
List<Users> usersList = [];
List<Users> childUsers = [];
List<Map<String, dynamic>> userList = [];
bool noUserList = false;
String UserLevel = "0";
List<CollectionList> collection = [];
List<DebtorsAgingList> target = [];

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

double Collections = 0;
String CollectionsStr = "";
String CollectionsGoalStr = "";
int CollectionPercentage = 0;
String CollectionPercentageStr = "";
String CurrentMonthCollectionsStr = "";
double CurrentMonthCollections = 0;
double CollectionGoal = 0;
double LastMonthCollections = 0;
String LastMonthCollectionsStr = "";
double LastMonthTarget = 0;
String LastMonthTargetStr = "";
int LastMonthPercentage = 0;
double CurrentQtrCollections = 0;
String CurrentQtrCollectionsStr = "";
double CurrentQtrTarget = 0;
String CurrentQtrTargetStr = "";
int CurrentQtrPercentage = 0;
double YtdCollections = 0;
String YtdCollectionsStr = "";
double YtdTarget = 0;
String YtdTargetStr = "";
int YtdPercentage = 0;
double CurrentMonthCollectionsPercentage = 0;
String CurrentMonthCollectionsPercentageStr = "";
String LastMonthPercentageStr = "";
String CurrentQtrPercentageStr = "";
String YtdPercentageStr = "";

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

double receivablesAmount = 0;
String receivablesAmountStr = "";
double overDue = 0;
String overDueStr = "";
double due = 0;
String dueStr = '';
double advance = 0;
String advanceStr = '';
double netReceivables = 0;
String netReceivablesStr = "";
double grossReceivables = 0;
String grossReceivablesStr = "";
int receivablePercentage = 0;
int netReceivablePercentage = 0;
String notDueStr = "";
double notDue = 0.0;

double otherPercent = 0.0;
double distributorPercent = 0.0;
double hospitalPercent = 0.0;
bool chartDataLoadedProductMargin = false;

String touchedGroup = "";
String touchedItem = "";
double selectedChart = 0;

bool showingAllData = true;
bool showingNHData = true;
bool showingSalesData = true;
bool showingOfficeData = true;

int selectedCheckbox = 1;

List<String> selectedSalesData = [];

final List<String> categories = ['Dates'];

List<List<String>> filterOptions = [[]];

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

List<DebtorsAgingList> targetListTemp = target;

List<String> listOfRSM = [];
List<String> listOfASM = [];
List<String> listOfTSM = [];

double sumOfCustomerCategoryWise = 0;

Map<String, Map<String, bool>> allCategoriesState = {};

int selectedCategoryIndex = 0;

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
List<ItemCostList> tempCostList = [];
YTDSalesList ytdSalesList = YTDSalesList(ytdData: []);
ProductMarginList productMarginList = ProductMarginList(productMarginData: []);
ProductMarginList productMarginListGraph = ProductMarginList(
  productMarginData: [],
);
bool YtdSalesBarChartData = false;

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

// class ProductWiseMarginProviderTemp with ChangeNotifier {
//   List<SalesList> _salesList = [];
//   List<SalesList> get salesList => _salesList;
//   void updateSalesList(List<SalesList> newSalesList) {
//     _salesList = newSalesList;
//     notifyListeners();
//   }
// }
//
// class ProductWiseMarginItemCostProviderTemp with ChangeNotifier {
//   List<ItemCostList> _itemCostList = [];
//   List<ItemCostList> get itemCostList => _itemCostList;
//   void updateItemCostList(List<ItemCostList> newCostList) {
//     _itemCostList = newCostList;
//     notifyListeners();
//   }
// }

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

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
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
        context.read<ProductWiseMarginProvider>().updateSalesList(salesList);
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        salesTemp = salesList
            .where((test) => test.invoiceType == "Sales")
            .toList();
        if (int.parse(UserLevel) == 5) {
          sales = salesList
              .where((test) => test.invoiceType == "Sales")
              .toList();
        } else if (int.parse(UserLevel) == 4) {
          sales = salesList
              .where((test) => test.invoiceType == "Sales")
              .toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          sales = salesList
              .where((test) => test.invoiceType == "Sales")
              .toList();
        } else {
          sales = salesList
              .where((test) => test.invoiceType == "Sales")
              .toList();
        }
      });
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadItemCost(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<ItemCostList> salesList = [];
    try {
      do {
        var body = {"Index": index.toString(), "Limit": limit.toString()};
        const apiUrl = '${ApiHelper.baseUrl}BicxoItemCostList';
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
            List<ItemCostList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => ItemCostList.fromJson(item))
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
        context.read<ProductWiseMarginItemCostProvider>().updateItemCostList(
          salesList,
        );

        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();

        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          itemCostList = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          itemCostList = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          itemCostList = salesList.toList();
        } else {
          itemCostList = salesList.toList();
        }
      });
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
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

    await _loadSales(userName, userLevel);
    await _loadItemCost(userName, userLevel);
    await _loadYtdSalesBarChartData("", "");
    chartDataLoadedProductMargin = true;
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
      // allReceivablesFinanceList = AllReceivablesFinanceList(agingData: []);
      advanceCustomerList = AdvanceFromCustomersList(agingData: []);
      customerAnalysisFinanceList = CustomerAnalysisFinanceList(
        customerData: [],
      );
      tsmwiseCollectionList = TsmwiseCollectionList(tsmwiseData: []);
      asmwiseCollectionList = AsmwiseCollectionList(asmwiseData: []);
      rsmwiseCollectionList = RsmwiseCollectionList(rsmwiseData: []);
    });
  }

  void toggleCheckbox() {
    setState(() {
      receivablesAmount = 0;
      overDue = 0;
      notDue = 0;
      netReceivables = 0;
      advance = 0;
      grossReceivables = 0;
      chartDataLoadedProductMargin = false;
      receivablesAmountStr = "";
      loadData("");
      // selectedCheckbox = index;
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
      receivablesAmountStr = "";
      receivablesAmount = 0;
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

  List<BarChartGroupData> _monthlyAnalysisChartData(
    List<ProductMarginData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.marginPercent,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemSubGroupChartData(
    List<SubGroupMarginTotal> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.marginPercent,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Widget buildCheckbox(int index) {
    return GestureDetector(
      onTap: () => toggleCheckbox(),
      child: Checkbox(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
        side: WidgetStateBorderSide.resolveWith(
          (states) => const BorderSide(width: 1.0, color: Color(0xFF8F8F8F)),
        ),
        value: selectedCheckbox == index,
        onChanged: (_) => toggleCheckbox(),
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

  //   Future<void> _loadYtdSalesBarChartData(String? itemGroup) async {
  //     Map<String, List<SalesList>> salesByCustomer = {};
  //     Map<String, List<SalesList>> salesByItem = {};
  //     String bomCost = '';
  //     List<ProductMarginData> ytdSalesDataList = [];
  //     var tmpSales = sales.toList();
  //
  //     for (var sale in tmpSales) {
  //       salesByCustomer.putIfAbsent(sale.code, () => []).add(sale);
  //     }
  //
  //     for (var customerCode in salesByCustomer.keys) {
  //       var customerSales = salesByCustomer[customerCode]!;
  //
  //       //only invoice
  //
  //       salesByItem.clear();
  //       for (var sale in customerSales) {
  //         salesByItem.putIfAbsent(sale.code, () => []).add(sale);
  //       }
  //
  //       for (var itemCode in salesByItem.keys) {
  //         var itemSales = salesByItem[itemCode]!;
  //         var firstItemSale = itemSales.first;
  //
  //         var matchingItems =
  //             itemCostList.where((test) => firstItemSale.code == test.itemCode);
  //
  //         bomCost = matchingItems.isNotEmpty ? matchingItems.first.itemCost : "0";
  //
  //         List<double> monthlyQty = List.filled(12, 0.0);
  //         List<double> monthlyValue = List.filled(12, 0.0);
  //
  //         for (int i = 0; i < 12; i++) {
  //           DateTime startDate = addMonth(fiscalYearStartDate!, i);
  //           DateTime endDate =
  //               addMonth(startDate, 1).add(const Duration(days: -1));
  //
  //           for (var sale in itemSales) {
  //             DateTime invoiceDate =
  //                 DateFormat('dd/MM/yyyy').parse(sale.invoiceDate);
  //             if (invoiceDate.isAtLeast(startDate) &&
  //                 invoiceDate.isAtMost(endDate)) {
  //               double rowTotal = double.tryParse(sale.rowTotal) ?? 0.0;
  //               double quantity = double.tryParse(sale.quantity) ?? 0.0;
  //               if (sale.invoiceType == "Sales Return") {
  //                 rowTotal *= -1;
  //                 quantity *= -1;
  //               }
  //               monthlyValue[i] += rowTotal;
  //               monthlyQty[i] += quantity;
  //             }
  //           }
  //         }
  //
  //         if (monthlyValue.reduce((a, b) => a + b) != 0) {
  //           ytdSalesDataList.add(ProductMarginData(
  //             itemNo: firstItemSale.code,
  //             itemDescription: firstItemSale.description,
  //             itemSubGroup: firstItemSale.itemSubGroup,
  //             quantity: monthlyQty.reduce((a, b) => a + b).toStringAsFixed(2),
  //             saleAmt: monthlyValue.reduce((a, b) => a + b).toStringAsFixed(2),
  //             avgSellingPrice: (monthlyValue.reduce((a, b) => a + b) /
  //                     monthlyQty.reduce((a, b) => a + b))
  //                 .toStringAsFixed(2),
  //             bomCost: double.parse(bomCost).toStringAsFixed(2),
  //             perUnitMarginAmount: ((monthlyValue.reduce((a, b) => a + b) /
  //                         monthlyQty.reduce((a, b) => a + b)) -
  //                     double.parse(bomCost))
  //                 .toStringAsFixed(2),
  //             totalMarginAmount: (((monthlyValue.reduce((a, b) => a + b) /
  //                             monthlyQty.reduce((a, b) => a + b)) -
  //                         double.parse(bomCost)) *
  //                     monthlyQty.reduce((a, b) => a + b))
  //                 .toStringAsFixed(2),
  //             marginPercent: (((monthlyValue.reduce((a, b) => a + b) /
  //                         monthlyQty.reduce((a, b) => a + b)) -
  //                     double.parse(bomCost)) /
  //                 (monthlyValue.reduce((a, b) => a + b) /
  //                     monthlyQty.reduce((a, b) => a + b)) *
  //                 100),
  //             // mayQty: monthlyQty[1],
  //             // mayValue: monthlyValue[1],
  //             // junQty: monthlyQty[2],
  //             // junValue: monthlyValue[2],
  //             // julQty: monthlyQty[3],
  //             // julValue: monthlyQty[3],
  //             // augQty: monthlyQty[4],
  //             // augValue: monthlyValue[4],
  //             // sepQty: monthlyQty[5],
  //             // sepValue: monthlyValue[5],
  //             // octQty: monthlyQty[6],
  //             // octValue: monthlyValue[6],
  //             // novQty: monthlyQty[7],
  //             // novValue: monthlyValue[7],
  //             // decQty: monthlyQty[8],
  //             // decValue: monthlyValue[8],
  //             // janQty: monthlyQty[9],
  //             // janValue: monthlyValue[9],
  //             // febQty: monthlyQty[10],
  //             // febValue: monthlyValue[10],
  //             // marQty: monthlyQty[11],
  //             // marValue: monthlyValue[11],
  //             // ytdTotalValue: monthlyValue.reduce((a, b) => a + b),
  //             // ytdTotalQty: monthlyQty.reduce((a, b) => a + b),
  //           ));
  //         }
  //         customerSales.clear();
  //       }
  //     }
  //
  //     setState(() {
  //       ytdSalesDataList.sort((a, b) => a.itemNo.compareTo(b.itemNo));
  //
  //       ytdSalesDataList.removeWhere(
  //           (item) => item.itemSubGroup == "" || item.itemSubGroup.isEmpty);
  //
  //       var filteredList = ytdSalesDataList
  //           .where(
  //               (item) => item.itemSubGroup != "" && item.itemSubGroup.isNotEmpty)
  //           .toList();
  //
  //       productMarginList = ProductMarginList(productMarginData: filteredList);
  //
  //       filteredList.sort((a, b) => b.marginPercent.compareTo(a.marginPercent));
  //       productMarginListGraph =
  //           ProductMarginList(productMarginData: filteredList);
  //
  //       YtdSalesBarChartData = true;
  //     });
  //
  //     List<ProductMarginData> data = productMarginList.productMarginData;
  //
  //     double overallTotal = data.fold(0.0, (sum, item) {
  //       return sum + (double.tryParse(item.totalMarginAmount) ?? 0.0);
  //     });
  //
  //     Map<String, double> subgroupSums = {};
  //     for (var item in data) {
  //       final margin = double.tryParse(item.totalMarginAmount) ?? 0.0;
  //       subgroupSums.update(
  //         item.itemSubGroup,
  //         (existing) => existing + margin,
  //         ifAbsent: () => margin,
  //       );
  //     }
  //
  //     itemSubGroupGraph = subgroupSums.entries.map((e) {
  //       final pct = overallTotal > 0 ? (e.value / overallTotal) * 100 : 0.0;
  //       return SubGroupMarginTotal(
  //         itemSubGroup: e.key,
  //         totalMarginAmount: e.value,
  //         marginPercent: pct,
  //       );
  //     }).toList();
  //
  //     itemSubGroupGraph.sort((a, b) => b.marginPercent.compareTo(a.marginPercent));
  //     itemSubGroupGraphList = SubGroupMarginTotalList(data: itemSubGroupGraph);
  //
  // // Helper class to store the result
  //   }

  Future<void> _loadYtdSalesBarChartData(
    String? itemGroup,
    String? item,
  ) async {
    Map<String, List<SalesList>> salesByCustomer = {};
    List<ProductMarginData> ytdSalesDataList = [];

    var tmpSales = sales.toList();
    for (var sale in tmpSales) {
      salesByCustomer.putIfAbsent(sale.code, () => []).add(sale);
    }

    for (var customerCode in salesByCustomer.keys) {
      var customerSales = salesByCustomer[customerCode]!;

      Map<String, List<SalesList>> salesByItem = {};
      for (var sale in customerSales) {
        salesByItem.putIfAbsent(sale.code, () => []).add(sale);
      }

      for (var itemCode in salesByItem.keys) {
        var itemSales = salesByItem[itemCode]!;
        var firstItemSale = itemSales.first;

        var matchingItems = itemCostList.where(
          (c) => firstItemSale.code == c.itemCode,
        );
        final double bomCost = matchingItems.isNotEmpty
            ? double.tryParse(matchingItems.first.itemCost) ?? 0.0
            : 0.0;

        List<double> monthlyQty = List.filled(12, 0.0);
        List<double> monthlyValue = List.filled(12, 0.0);

        for (int i = 0; i < 12; i++) {
          DateTime startDate = addMonth(fiscalYearStartDate!, i);
          DateTime endDate = addMonth(
            startDate,
            1,
          ).subtract(const Duration(days: 1));

          for (var sale in itemSales) {
            DateTime invoiceDate = sale.invoiceDate;
            if (invoiceDate.isAtLeast(startDate) &&
                invoiceDate.isAtMost(endDate)) {
              double rowTotal = double.tryParse(sale.rowTotal) ?? 0.0;
              double quantity = double.tryParse(sale.quantity) ?? 0.0;
              if (sale.invoiceType == "Sales Return") {
                rowTotal *= -1;
                quantity *= -1;
              }
              monthlyValue[i] += rowTotal;
              monthlyQty[i] += quantity;
            }
          }
        }

        final totalQty = monthlyQty.reduce((a, b) => a + b);
        final totalValue = monthlyValue.reduce((a, b) => a + b);
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
    }

    ytdSalesDataList.sort((a, b) => a.itemNo.compareTo(b.itemNo));
    ytdSalesDataList.removeWhere((d) => d.itemSubGroup.isEmpty);
    var productList = ytdSalesDataList;

    List<ProductMarginData> filteredData = productList;
    if (itemGroup != null && itemGroup.isNotEmpty) {
      filteredData = productList
          .where((d) => d.itemSubGroup == itemGroup)
          .toList();
    }

    if (item != null && item.isNotEmpty) {
      filteredData = filteredData
          .where((d) => d.itemDescription.contains(item))
          .toList();
    }

    setState(() {
      productMarginList = ProductMarginList(productMarginData: filteredData);

      filteredData.sort((a, b) => b.marginPercent.compareTo(a.marginPercent));
      productMarginListGraph = ProductMarginList(
        productMarginData: filteredData,
      );

      double overallTotal = filteredData.fold(0.0, (sum, item) {
        return sum + (double.tryParse(item.totalMarginAmount) ?? 0.0);
      });

      Map<String, double> subgroupSums = {};
      for (var item in filteredData) {
        final m = double.tryParse(item.totalMarginAmount) ?? 0.0;
        subgroupSums.update(
          item.itemSubGroup,
          (ex) => ex + m,
          ifAbsent: () => m,
        );
      }

      itemSubGroupGraph = subgroupSums.entries.map((e) {
        final pct = overallTotal > 0 ? (e.value / overallTotal) * 100 : 0.0;
        return SubGroupMarginTotal(
          itemSubGroup: e.key,
          totalMarginAmount: e.value,
          marginPercent: pct,
        );
      }).toList();
      itemSubGroupGraph.sort(
        (a, b) => b.marginPercent.compareTo(a.marginPercent),
      );
      itemSubGroupGraphList = SubGroupMarginTotalList(data: itemSubGroupGraph);

      YtdSalesBarChartData = true;
    });
  }

  Future<void> generateSalesAnalysisYTDExcel() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow([
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
      ]),
    );

    for (int column = 0; column < 11; column++) {
      var cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
      );
      cell.cellStyle = xl.CellStyle(bold: true, fontSize: 14);

      // sheet.setColAutoFit(column);
    }

    productMarginList.productMarginData.removeWhere(
      (item) => double.parse(item.quantity) < 0,
    );

    for (var ytdData in productMarginList.productMarginData) {
      sheet.appendRow(
        toCellRow([
          ytdData.itemNo,
          ytdData.itemDescription,
          ytdData.itemSubGroup,
          ytdData.quantity,
          ytdData.saleAmt,
          ytdData.avgSellingPrice,
          ytdData.bomCost,
          ytdData.perUnitMarginAmount,
          ytdData.totalMarginAmount,
          ytdData.marginPercent.toStringAsFixed(0),
        ]),
      );
    }

    xl.CellStyle centerCellStyle = xl.CellStyle(
      verticalAlign: xl.VerticalAlign.Center,
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    int numberOfRows = productMarginList.productMarginData.length;

    for (int rowIndex = 0; rowIndex <= numberOfRows; rowIndex++) {
      for (int colIndex = 0; colIndex < 10; colIndex++) {
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
      // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');

      final excelBytes = excel.encode()!;
      saveAndOpenExcel('productMarginReport.xlsx', excelBytes);

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
      final file = File('$storageDir/productMarginReport.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> generateItemGroupWise() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow(['Name', 'Margin Percentage', 'Total Margin Amount']),
    );

    for (int column = 0; column < 11; column++) {
      var cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
      );
      cell.cellStyle = xl.CellStyle(bold: true, fontSize: 14);

      // sheet.setColAutoFit(column);
    }

    for (var ytdData in itemSubGroupGraphList.data) {
      sheet.appendRow(
        toCellRow([
          ytdData.itemSubGroup,
          ytdData.totalMarginAmount,
          ytdData.marginPercent.toStringAsFixed(0),
        ]),
      );
    }

    xl.CellStyle centerCellStyle = xl.CellStyle(
      verticalAlign: xl.VerticalAlign.Center,
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    int numberOfRows = productMarginList.productMarginData.length;

    for (int rowIndex = 0; rowIndex <= numberOfRows; rowIndex++) {
      for (int colIndex = 0; colIndex < 10; colIndex++) {
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
      // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');

      final excelBytes = excel.encode()!;
      saveAndOpenExcel('productMarginReport.xlsx', excelBytes);

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
      final file = File('$storageDir/productMarginReport.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> generatePendingOrderExcel() async {
    // await _loadYtdSalesBarChartData();
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
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
        ]),
      );
      for (var element in productMarginList.productMarginData) {
        sheet.appendRow(
          toCellRow([
            element.itemNo,
            element.itemDescription,
            element.itemSubGroup,
            element.quantity,
            element.saleAmt,
            element.avgSellingPrice,
            element.bomCost,
            element.perUnitMarginAmount,
            element.totalMarginAmount,
            element.marginPercent,
          ]),
        );
        // totalOrderedQty += dailyData.orderedQty;
        // totalDispatchedQty += dailyData.dispatchedQty;
        // totalPendingQty += dailyData.pendingQty;
      }
      // sheet.appendRow(toCellRow(
      //     ["Total", totalOrderedQty, totalDispatchedQty, totalPendingQty]);

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('pendingOrders.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/pendingOrders.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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

    filterOptions = [
      ['OFFICE - Drs.', 'NH GROUP. - Drs.', 'Sales Team'],
      ['Hospital', 'Distributor', 'Other'],
      ['Credit Note', 'Invoice', 'Journal', 'Receipt'],
      listOfRSM,
      listOfASM,
      listOfTSM,
      ['Not Dues', 'Overdue'],
      ['Advance', 'Receivables'],
    ];

    selectedFinanceReceivablesOptions = filterOptions
        .map((options) => List<bool>.filled(options.length, false))
        .toList();

    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
  }

  @override
  Widget build(BuildContext context) {
    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
    return chartDataLoadedProductMargin == true
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
                                "${formatDateString(fiscalYearStartDate!)} - ${formatDateString(currentDate!)}",
                              ),
                      ],
                    ),
                    // Row(
                    //   children: [
                    //     // IconButton(
                    //     //   onPressed: () {
                    //     //     showFilterBottomSheet(context);
                    //     //   },
                    //     //   icon: const Icon(Icons.filter_alt_outlined),
                    //     // ),
                    //   ],
                    // ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Product Margin Report - Item Wise",
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
                                    generateSalesAnalysisYTDExcel();
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _dailyCostingGraph(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Product Margin Report - Item Group Wise",
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
                                    generateItemGroupWise();
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _itemSubGroupWise(),
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

  Widget _dailyCostingGraph() {
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
            barGroups: _monthlyAnalysisChartData(
              productMarginListGraph.productMarginData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItem = touchedItem == ""
                          ? productMarginListGraph
                                .productMarginData[barTouchResponse.spot!.spot.x
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
                if (barTouchResponse != null && barTouchResponse.spot != null) {
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
                                      chartDataLoadedProductMargin = false;
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        chartDataLoadedProductMargin = false;
                                        loadDataFuture = removeFilter();
                                        Navigator.pop(context);
                                        chartDataLoadedProductMargin = true;
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
