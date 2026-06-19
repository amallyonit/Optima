// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
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
import 'package:optima/classes/leads.dart';
import 'package:optima/login_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';
import 'package:optima/pages/dashboardPages/pdf_helper_web.dart';

import '../../../notificationService.dart';

class InventoryAnalysis extends StatefulWidget {
  const InventoryAnalysis({super.key});

  @override
  State<InventoryAnalysis> createState() => _InventoryAnalysisState();
}

class InventoryListInventoryAnalysisProvider with ChangeNotifier {
  List<InventoryList> _salesList = [];
  List<InventoryList> get salesList => _salesList;
  void updateInventoryList(List<InventoryList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class InventoryListInventoryLevelAnalysisProvider with ChangeNotifier {
  List<InventoryLevelList> _salesList = [];
  List<InventoryLevelList> get salesList => _salesList;
  void updateInventoryLevelList(List<InventoryLevelList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
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
int currentQuarter = 0;

List<Users> usersList = [];
List<Users> usersListForFilter = [];
List<Users> childUsers = [];
List<Map<String, dynamic>> userList = [];
List<MyNode> nodes = [];
bool noUserList = false;

double selectedChart = 0;

List<InventoryList> inventory = [];
List<InventoryLevelList> inventoryLevel = [];

ReceivablesFinanceList receivablesFinanceList = ReceivablesFinanceList(
  agingData: [],
);

InventoryAgingList inventoryAgingList = InventoryAgingList(agingData: []);
WarehouseInventoryList warehouseLocationList = WarehouseInventoryList(
  warehouseData: [],
);
InventoryLevelGraphList inventoryGraphList = InventoryLevelGraphList(
  levelData: [],
);
ItemGroupWiseInventoryList itemGroupList = ItemGroupWiseInventoryList(
  itemGroupData: [],
);
ItemSubGroupWiseInventoryList itemSubGroupList = ItemSubGroupWiseInventoryList(
  itemSubGroupData: [],
);

String touchedAging = "";
String touchedWarehouseLocation = "";
String touchedItemGroup = "";
String touchedItemSubGroup = "";

double totalInventory = 0;

bool qtyOrValCheck = true;

Map<String, double> warehouseTotals = {};

class _InventoryAnalysisState extends State<InventoryAnalysis> {
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  bool showDrillDownChart = false;
  bool chartDataLoaded = false;

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

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
        if (maxValue >= 300000) {
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

  SideTitles get _bottomTitlesInventoryAgeing => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<InventoryAgingData> mData = inventoryAgingList.agingData;
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

  SideTitles get _bottomTitlesWarehouseLocationInventory => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<WarehouseInventoryData> mData = warehouseLocationList.warehouseData;
      text = mData.elementAt(value.toInt()).warehouseName;
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

  SideTitles get _bottomTitlesInventoryLevel => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<InventoryLevelGraphData> mData = inventoryGraphList.levelData;
      text = mData.elementAt(value.toInt()).itemName;
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

  SideTitles get _bottomTitlesItemGroupWise => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemGroupWiseInventoryData> mData = itemGroupList.itemGroupData;
      text = mData.elementAt(value.toInt()).groupName;
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

  SideTitles get _bottomTitlesItemSubGroupWise => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemSubGroupWiseInventoryData> mData =
          itemSubGroupList.itemSubGroupData;
      text = mData.elementAt(value.toInt()).subGroupName;
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

  List<BarChartGroupData> _inventoryAgeingChartData(
    List<InventoryAgingData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.agingTotal,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _warehouseLocationInventoryChartData(
    List<WarehouseInventoryData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.quantity,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _inventoryLevelChartData(
    List<InventoryLevelGraphData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  color: const Color(0xFF97D7F3),
                  toY: chartData.total,
                  fromY: 0,
                  show: true,
                ),
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.minLevel,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemGroupWiseChartData(
    List<ItemGroupWiseInventoryData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.quantity,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemSubGroupWiseChartData(
    List<ItemSubGroupWiseInventoryData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.quantity,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
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

  InventoryAgingSummary summarizeCollectionTargets(
    Iterable<InventoryList> inventory,
  ) {
    InventoryAgingSummary summary = InventoryAgingSummary();
    String overDueDays = "";
    for (var element in inventory) {
      overDueDays = element.ageingBrackets;
      if (overDueDays == "<30 Days") {
        summary.a0to30DaysTotal += (qtyOrValCheck
            ? double.parse(element.totalQuantity)
            : double.parse(element.totalValue));
      } else if (overDueDays == "31-45 Days") {
        summary.a31to45DaysTotal += (qtyOrValCheck
            ? double.parse(element.totalQuantity)
            : double.parse(element.totalValue));
      } else if (overDueDays == "46-60 Days") {
        summary.a46to60DaysTotal += (qtyOrValCheck
            ? double.parse(element.totalQuantity)
            : double.parse(element.totalValue));
      } else if (overDueDays == "61-90 Days") {
        summary.a61to90DaysTotal += (qtyOrValCheck
            ? double.parse(element.totalQuantity)
            : double.parse(element.totalValue));
      } else if (overDueDays == "91-120 Days") {
        summary.a91to120DaysTotal += (qtyOrValCheck
            ? double.parse(element.totalQuantity)
            : double.parse(element.totalValue));
      } else if (overDueDays == "121-150 Days") {
        summary.a121to150DaysTotal += (qtyOrValCheck
            ? double.parse(element.totalQuantity)
            : double.parse(element.totalValue));
      } else if (overDueDays == "151-180 Days") {
        summary.a151to180DaysTotal += (qtyOrValCheck
            ? double.parse(element.totalQuantity)
            : double.parse(element.totalValue));
      } else if (overDueDays == "181-365 Days") {
        summary.a181to365DaysTotal += (qtyOrValCheck
            ? double.parse(element.totalQuantity)
            : double.parse(element.totalValue));
      } else if (overDueDays == "366-730 Days") {
        summary.a366to730DaysTotal += (qtyOrValCheck
            ? double.parse(element.totalQuantity)
            : double.parse(element.totalValue));
      } else if (overDueDays == ">730 Days") {
        summary.a730DaysTotal += (qtyOrValCheck
            ? double.parse(element.totalQuantity)
            : double.parse(element.totalValue));
      }
    }
    return summary;
  }

  Future<void> _loadInventory(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<InventoryList> salesList = [];
    int monthIndex = DateTime.now().month;
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
        const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<InventoryList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => InventoryList.fromJson(item))
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
        context
            .read<InventoryListInventoryAnalysisProvider>()
            .updateInventoryList(salesList);
        inventory = salesList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading inventory data.",
      );
    }
  }

  Future<void> _loadInventoryLevel(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<InventoryLevelList> salesList = [];
    try {
      do {
        var body = {
          "Index": index.toString(),
          "Limit": limit.toString(),
          "type": "All",
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoStockStatusList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<InventoryLevelList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => InventoryLevelList.fromJson(item))
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
        context
            .read<InventoryListInventoryLevelAnalysisProvider>()
            .updateInventoryLevelList(salesList);
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          inventoryLevel = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          inventoryLevel = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          inventoryLevel = salesList.toList();
        } else {
          inventoryLevel = salesList.toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading inventory level data.",
      );
    }
  }

  Future<void> _loadInventoryAgingData(
    List<InventoryList> inventoryList,
  ) async {
    List<InventoryAgingData> receivablesAgingDataList = [];

    InventoryAgingSummary summary = summarizeCollectionTargets(inventoryList);

    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "0-30",
        agingTotal: summary.a0to30DaysTotal,
      ),
    );

    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "31-45",
        agingTotal: summary.a31to45DaysTotal,
      ),
    );

    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "46-60",
        agingTotal: summary.a46to60DaysTotal,
      ),
    );

    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "61-90",
        agingTotal: summary.a61to90DaysTotal,
      ),
    );

    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "91-120",
        agingTotal: summary.a91to120DaysTotal,
      ),
    );

    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "121-150",
        agingTotal: summary.a121to150DaysTotal,
      ),
    );

    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "151-180",
        agingTotal: summary.a151to180DaysTotal,
      ),
    );

    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "181-365",
        agingTotal: summary.a181to365DaysTotal,
      ),
    );

    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "366-730",
        agingTotal: summary.a366to730DaysTotal,
      ),
    );

    receivablesAgingDataList.add(
      InventoryAgingData(agingGroup: "731+", agingTotal: summary.a730DaysTotal),
    );

    inventoryAgingList = InventoryAgingList(
      agingData: receivablesAgingDataList,
    );
  }

  Future<void> _loadWarehouseLocationWiseInventory(
    List<InventoryList> inventoryList,
  ) async {
    List<WarehouseInventoryData> warehouseData = [];

    Map<String, double> warehouseTotals = {};
    Map<String, String> warehouseCodeMap = {};
    for (var item in inventoryList) {
      double value = qtyOrValCheck
          ? double.parse(item.totalQuantity)
          : double.parse(item.totalValue);

      warehouseTotals.update(
        item.warehouseName,
        (existing) => existing + value,
        ifAbsent: () => value,
      );
      warehouseCodeMap[item.warehouseName] = item.warehouseCode;
    }

    warehouseTotals.forEach((name, total) {
      warehouseData.add(
        WarehouseInventoryData(
          warehouseCode: warehouseCodeMap[name] ?? "",
          warehouseName: name,
          quantity: total,
        ),
      );
    });

    warehouseData.sort((a, b) => b.quantity.compareTo(a.quantity));

    warehouseLocationList = WarehouseInventoryList(
      warehouseData: warehouseData,
    );
  }

  Future<void> _loadInventoryLevelGraph(
    List<InventoryLevelList> inventoryList,
  ) async {
    List<InventoryLevelGraphData> levelData = [];

    Map<String, InventoryLevelGraphData> itemMap = {};

    for (var item in inventoryList) {
      double inStock = double.tryParse(item.inStock) ?? 0;
      double minInventory = double.tryParse(item.minInventory) ?? 0;
      double maxInventory = double.tryParse(item.maxInventory) ?? 0;

      itemMap[item.itemDescription] = InventoryLevelGraphData(
        itemName: item.itemDescription,
        inStock: inStock,
        minLevel: minInventory,
        maxLevel: maxInventory,
        total: inStock + minInventory + maxInventory,
      );
    }

    levelData = itemMap.values.toList();
    levelData.sort((a, b) => b.total.compareTo(a.total));
    inventoryGraphList = InventoryLevelGraphList(levelData: levelData);
  }

  Future<void> _loadItemGroupWiseInventory(
    List<InventoryList> inventoryList,
  ) async {
    List<ItemGroupWiseInventoryData> warehouseData = [];
    Map<String, double> groupTotals = {};

    for (var item in inventoryList) {
      double value = qtyOrValCheck
          ? double.parse(item.totalQuantity)
          : double.parse(item.totalValue);

      groupTotals.update(
        item.groupName,
        (existing) => existing + value,
        ifAbsent: () => value,
      );
    }

    groupTotals.forEach((name, total) {
      warehouseData.add(
        ItemGroupWiseInventoryData(groupName: name, quantity: total),
      );
    });

    warehouseData.sort((a, b) => b.quantity.compareTo(a.quantity));
    itemGroupList = ItemGroupWiseInventoryList(itemGroupData: warehouseData);
    totalInventory = itemGroupList.itemGroupData.fold(
      0,
      (prev, elem) => prev + elem.quantity,
    );
  }

  Future<void> _loadItemSubGroupWiseInventory(
    List<InventoryList> inventoryList,
  ) async {
    List<ItemSubGroupWiseInventoryData> warehouseData = [];
    Map<String, double> subGroupTotals = {};

    for (var item in inventoryList) {
      double value = qtyOrValCheck
          ? double.parse(item.totalQuantity)
          : double.parse(item.totalValue);

      subGroupTotals.update(
        item.itemSubGroup,
        (existing) => existing + value,
        ifAbsent: () => value,
      );
    }

    subGroupTotals.forEach((name, total) {
      warehouseData.add(
        ItemSubGroupWiseInventoryData(subGroupName: name, quantity: total),
      );
    });

    warehouseData.sort((a, b) => b.quantity.compareTo(a.quantity));

    itemSubGroupList = ItemSubGroupWiseInventoryList(
      itemSubGroupData: warehouseData,
    );
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
    await _loadUserListForFilter(
      userId,
      userJwtToken,
      userMailID,
      int.tryParse(userLevel) ?? 0,
    );
    await _loadInventory(userName, userLevel);
    await _loadInventoryLevel(userName, userLevel);

    var filteredInventory = filterInventoryList(
      inventory,
      aging: "",
      WarehouseLocation: "",
      ItemGroupWise: "",
      ItemSubGroupWise: "",
    );
    var filteredInventoryLevel = filterInventoryLevelList(
      inventoryLevel,
      aging: "",
      WarehouseLocation: "",
      ItemGroupWise: "",
      ItemSubGroupWise: "",
    );
    await Future.wait([
      _loadInventoryAgingData(filteredInventory),
      _loadWarehouseLocationWiseInventory(filteredInventory),
      _loadInventoryLevelGraph(filteredInventoryLevel),
      _loadItemGroupWiseInventory(filteredInventory),
      _loadItemSubGroupWiseInventory(filteredInventory),
    ]);
    chartDataLoaded = true;
  }

  Future<void> loadQuantityOrValue(String selectedUser) async {
    var filteredInventory = filterInventoryList(
      inventory,
      aging: "",
      WarehouseLocation: "",
      ItemGroupWise: "",
      ItemSubGroupWise: "",
    );
    var filteredInventoryLevel = filterInventoryLevelList(
      inventoryLevel,
      aging: "",
      WarehouseLocation: "",
      ItemGroupWise: "",
      ItemSubGroupWise: "",
    );
    await Future.wait([
      _loadInventoryAgingData(filteredInventory),
      _loadWarehouseLocationWiseInventory(filteredInventory),
      _loadInventoryLevelGraph(filteredInventoryLevel),
      _loadItemGroupWiseInventory(filteredInventory),
      _loadItemSubGroupWiseInventory(filteredInventory),
    ]);
    chartDataLoaded = true;
  }

  List<InventoryList> filterInventoryList(
    List<InventoryList> collectionTargetList, {
    String? aging,
    String? WarehouseLocation,
    String? ItemGroupWise,
    String? ItemSubGroupWise,
  }) {
    List<InventoryList> filteredCollectionTargetList = [];
    String overDueDays = "";
    if (aging != null && aging.isNotEmpty) {
      if (aging == "0-30") {
        overDueDays = "<30 Days";
      } else if (aging == "31-45") {
        overDueDays = "31-45 Days";
      } else if (aging == "46-60") {
        overDueDays = "46-60 Days";
      } else if (aging == "61-90") {
        overDueDays = "61-90 Days";
      } else if (aging == "91-120") {
        overDueDays = "91-120 Days";
      } else if (aging == "121-150") {
        overDueDays = "121-150 Days";
      } else if (aging == "151-180") {
        overDueDays = "151-180 Days";
      } else if (aging == "181-365") {
        overDueDays = "181-365 Days";
      } else if (aging == "366-730") {
        overDueDays = "366-730 Days";
      } else if (aging == "731+") {
        overDueDays = ">730 Days";
      }
    }

    for (var target in collectionTargetList) {
      if ((WarehouseLocation == null ||
              WarehouseLocation.isEmpty ||
              target.warehouseName == WarehouseLocation) &&
          (aging == null ||
              aging.isEmpty ||
              target.ageingBrackets == overDueDays) &&
          (ItemGroupWise == null ||
              ItemGroupWise.isEmpty ||
              target.groupName == ItemGroupWise) &&
          (ItemSubGroupWise == null ||
              ItemSubGroupWise.isEmpty ||
              target.itemSubGroup == ItemSubGroupWise)) {
        filteredCollectionTargetList.add(target);
      }
    }
    return filteredCollectionTargetList;
  }

  List<InventoryLevelList> filterInventoryLevelList(
    List<InventoryLevelList> inventoryLevelList, {
    String? aging,
    String? WarehouseLocation,
    String? ItemGroupWise,
    String? ItemSubGroupWise,
  }) {
    List<InventoryLevelList> filteredInventoryLevelList = [];
    String overDueDays = "";
    if (aging != null && aging.isNotEmpty) {
      if (aging == "0-30") {
        overDueDays = "<30 Days";
      } else if (aging == "31-45") {
        overDueDays = "31-45 Days";
      } else if (aging == "46-60") {
        overDueDays = "46-60 Days";
      } else if (aging == "61-90") {
        overDueDays = "61-90 Days";
      } else if (aging == "91-120") {
        overDueDays = "91-120 Days";
      } else if (aging == "121-150") {
        overDueDays = "121-150 Days";
      } else if (aging == "151-180") {
        overDueDays = "151-180 Days";
      } else if (aging == "181-365") {
        overDueDays = "181-365 Days";
      } else if (aging == "366-730") {
        overDueDays = "366-730 Days";
      } else if (aging == "731+") {
        overDueDays = ">730 Days";
      }
    }

    for (var target in inventoryLevelList) {
      if ((WarehouseLocation == null ||
              WarehouseLocation.isEmpty ||
              target.warehouseName == WarehouseLocation) &&
          (aging == null ||
              aging.isEmpty ||
              target.mfgAgeingBrackets == overDueDays) &&
          (ItemGroupWise == null ||
              ItemGroupWise.isEmpty ||
              target.groupName == ItemGroupWise) &&
          (ItemSubGroupWise == null ||
              ItemSubGroupWise.isEmpty ||
              target.itemSubGroup == ItemSubGroupWise)) {
        filteredInventoryLevelList.add(target);
      }
    }
    return filteredInventoryLevelList;
  }

  Future<void> loadDataWithFilter(
    String? aging,
    String? WarehouseLocation,
    String? ItemGroupWise,
    String? ItemSubGroupWise,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    var filteredInventory = filterInventoryList(
      inventory,
      aging: aging,
      WarehouseLocation: WarehouseLocation,
      ItemGroupWise: ItemGroupWise,
      ItemSubGroupWise: ItemSubGroupWise,
    );
    var filteredInventoryLevel = filterInventoryLevelList(
      inventoryLevel,
      aging: aging,
      WarehouseLocation: WarehouseLocation,
      ItemGroupWise: ItemGroupWise,
      ItemSubGroupWise: ItemSubGroupWise,
    );
    await Future.wait([
      _loadInventoryAgingData(filteredInventory),
      _loadWarehouseLocationWiseInventory(filteredInventory),
      _loadInventoryLevelGraph(filteredInventoryLevel),
      _loadItemGroupWiseInventory(filteredInventory),
      _loadItemSubGroupWiseInventory(filteredInventory),
    ]);
    chartDataLoaded = true;
  }

  Future<void> removeFilter() async {
    clearVariables();
    LoadDates();
    var filteredInventory = filterInventoryList(
      inventory,
      aging: "",
      WarehouseLocation: "",
      ItemGroupWise: "",
      ItemSubGroupWise: "",
    );
    var filteredInventoryLevel = filterInventoryLevelList(
      inventoryLevel,
      aging: "",
      WarehouseLocation: "",
      ItemGroupWise: "",
      ItemSubGroupWise: "",
    );
    await Future.wait([
      _loadInventoryAgingData(filteredInventory),
      _loadWarehouseLocationWiseInventory(filteredInventory),
      _loadInventoryLevelGraph(filteredInventoryLevel),
      _loadItemGroupWiseInventory(filteredInventory),
      _loadItemSubGroupWiseInventory(filteredInventory),
    ]);
    chartDataLoaded = true;
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;
      inventoryAgingList = InventoryAgingList(agingData: []);
      warehouseLocationList = WarehouseInventoryList(warehouseData: []);
      inventoryGraphList = InventoryLevelGraphList(levelData: []);
      itemGroupList = ItemGroupWiseInventoryList(itemGroupData: []);
      itemSubGroupList = ItemSubGroupWiseInventoryList(itemSubGroupData: []);
      touchedAging = "";
      touchedWarehouseLocation = "";
      touchedItemGroup = "";
      touchedItemSubGroup = "";
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoaded = false;
      inventoryAgingList = InventoryAgingList(agingData: []);
      warehouseLocationList = WarehouseInventoryList(warehouseData: []);
      inventoryGraphList = InventoryLevelGraphList(levelData: []);
      itemGroupList = ItemGroupWiseInventoryList(itemGroupData: []);
      itemSubGroupList = ItemSubGroupWiseInventoryList(itemSubGroupData: []);
    });
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> generateInventoryAgingExcel(InventoryAgingList list) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Ageing Group', 'Ageing Group Total']));
      for (var monthlyData in list.agingData) {
        sheet.appendRow(
          toCellRow([monthlyData.agingGroup, monthlyData.agingTotal]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('inventoryAging.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/inventoryAging.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating inventory ageing excel.",
      );
    }
  }

  Future<void> generateInventoryAgingPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Inventory Aging',
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
                      'Ageing Group',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Ageing Group Total',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in inventoryAgingList.agingData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.agingGroup,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.agingTotal.toString(),
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
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/inventoryAging.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating inventory ageing pdf.",
      );
    }
  }

  Future<void> generateWarehouseLocationExcel(
    WarehouseInventoryList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Warehouse Name', 'Qty']));
      for (var monthlyData in list.warehouseData) {
        sheet.appendRow(
          toCellRow([monthlyData.warehouseName, monthlyData.quantity]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('warehouseLocation_inventory.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/warehouseLocation_inventory.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating warehouse location excel.",
      );
    }
  }

  Future<void> generateWarehouseLocationPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Warehouse Location-Wise Inventory',
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
                      'Warehouse Name',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Qty',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in warehouseLocationList.warehouseData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.warehouseName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.quantity.toString(),
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
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/warehouseLocation_inventory.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating warehouse location pdf.",
      );
    }
  }

  Future<void> generateItemGroupWiseInventoryExcel(
    ItemGroupWiseInventoryList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Item Group', 'Qty']));
      for (var monthlyData in list.itemGroupData) {
        sheet.appendRow(
          toCellRow([monthlyData.groupName, monthlyData.quantity]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('itemGroupWise_inventory.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemGroupWise_inventory.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating item group wise excel.",
      );
    }
  }

  Future<void> generateItemGroupWiseInventoryPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Item Group Wise Inventory',
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
                      'Item Group',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Qty',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in itemGroupList.itemGroupData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.groupName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.quantity.toString(),
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
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemGroupWise_inventory.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating item group wise pdf.",
      );
    }
  }

  Future<void> generateSubItemGroupWiseInventoryExcel(
    ItemSubGroupWiseInventoryList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Item Sub Group', 'Qty']));
      for (var monthlyData in list.itemSubGroupData) {
        sheet.appendRow(
          toCellRow([monthlyData.subGroupName, monthlyData.quantity]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('itemSubGroupWise_inventory.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemSubGroupWise_inventory.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating item sub group wise excel.",
      );
    }
  }

  Future<void> generateSubItemGroupWiseInventoryPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Item Sub Group Wise Inventory',
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
                      'Item Sub Group',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Qty',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in itemSubGroupList.itemSubGroupData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.subGroupName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.quantity.toString(),
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
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemSubGroupWise_inventory.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating item sub group wise pdf.",
      );
    }
  }

  Future<void> generateInventoryLevelExcel(InventoryLevelGraphList list) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow(['Item Name', 'Min-Level', 'Max-Level', 'In-Stock']),
      );
      for (var monthlyData in list.levelData) {
        sheet.appendRow(
          toCellRow([
            monthlyData.itemName,
            monthlyData.minLevel,
            monthlyData.maxLevel,
            monthlyData.inStock,
          ]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('inventoryLevel.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/inventoryLevel.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating inventory level excel.",
      );
    }
  }

  Future<void> generateInventoryLevelPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Inventory Level',
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
                      'Item Name',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Min Level',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Max Level',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'In Stock',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in inventoryGraphList.levelData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.itemName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.minLevel.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.maxLevel.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.inStock.toString(),
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
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemSubGroupWise_inventory.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating inventory level pdf.",
      );
    }
  }

  void toggleCheckbox() {
    setState(() {
      chartDataLoaded = false;
      qtyOrValCheck = !qtyOrValCheck;
    });
    loadQuantityOrValue("");
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
    final screenWidth = MediaQuery.of(context).size.width;
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
                      ],
                    ),
                  ],
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("View By:"),
                      const SizedBox(width: 10),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (qtyOrValCheck) {
                                  setState(() {
                                    qtyOrValCheck = false;
                                    chartDataLoaded = false;
                                  });
                                  loadQuantityOrValue("");
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: !qtyOrValCheck
                                      ? const Color(0xFF1976D2)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    bottomLeft: Radius.circular(6),
                                  ),
                                ),
                                child: Text(
                                  "Value",
                                  style: TextStyle(
                                    color: !qtyOrValCheck
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                if (!qtyOrValCheck) {
                                  setState(() {
                                    qtyOrValCheck = true;
                                    chartDataLoaded = false;
                                  });
                                  loadQuantityOrValue("");
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: qtyOrValCheck
                                      ? const Color(0xFF1976D2)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(6),
                                    bottomRight: Radius.circular(6),
                                  ),
                                ),
                                child: Text(
                                  "Quantity",
                                  style: TextStyle(
                                    color: qtyOrValCheck
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Container(
                          width: screenWidth - 30,
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
                                  'Total Inventory: ${formatAmount(totalInventory)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 150,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 120,
                          childAspectRatio: 0.4,
                        ),
                    itemCount: itemGroupList.itemGroupData.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  itemGroupList.itemGroupData[index].groupName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  formatAmount(
                                    itemGroupList.itemGroupData[index].quantity,
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
                          "Inventory Ageing",
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
                                  generateInventoryAgingExcel(
                                    inventoryAgingList,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  generateInventoryAgingPDF();
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
                  child: _inventoryAgeing(),
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
                          "Warehouse Location-wise Inventory",
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
                                  generateWarehouseLocationExcel(
                                    warehouseLocationList,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  generateWarehouseLocationPDF();
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
                  child: _warehouseLocationWiseInventory(),
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
                          "Item Group Wise Inventory",
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
                                  generateItemGroupWiseInventoryExcel(
                                    itemGroupList,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  generateItemGroupWiseInventoryPDF();
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
                  child: _itemGroupWiseInventory(),
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
                          "Item Sub Group Wise Inventory",
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
                                  generateSubItemGroupWiseInventoryExcel(
                                    itemSubGroupList,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  generateSubItemGroupWiseInventoryPDF();
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
                  child: _itemSubGroupWiseInventory(),
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
                          "Inventory Level",
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
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text("Min-Level", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("In-Stock", style: TextStyle(fontSize: 12)),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  generateInventoryLevelExcel(
                                    inventoryGraphList,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  generateInventoryLevelPDF();
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
                  child: _inventoryLevel(),
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

  Widget _inventoryAgeing() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = inventoryAgingList.agingData.length;
    if (inventoryAgingList.agingData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? inventoryAgingList.agingData
              .map((data) => data.agingTotal)
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
                sideTitles: _bottomTitlesInventoryAgeing,
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
            barGroups: _inventoryAgeingChartData(inventoryAgingList.agingData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedAging = touchedAging == ""
                          ? inventoryAgingList
                                .agingData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .agingGroup
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedAging,
                        touchedWarehouseLocation,
                        touchedItemGroup,
                        touchedItemSubGroup,
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
                    inventoryAgingList.agingData[grpIndex].agingGroup,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: qtyOrValCheck
                            ? "\nQty : ${formatAmount(inventoryAgingList.agingData[grpIndex].agingTotal)}"
                            : "\nVal : ${formatAmount(inventoryAgingList.agingData[grpIndex].agingTotal)}",
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

  Widget _warehouseLocationWiseInventory() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = warehouseLocationList.warehouseData.length;
    if (warehouseLocationList.warehouseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? warehouseLocationList.warehouseData
              .map((data) => data.quantity)
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
                sideTitles: _bottomTitlesWarehouseLocationInventory,
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
            barGroups: _warehouseLocationInventoryChartData(
              warehouseLocationList.warehouseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedWarehouseLocation = touchedWarehouseLocation == ""
                          ? warehouseLocationList
                                .warehouseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .warehouseName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedAging,
                        touchedWarehouseLocation,
                        touchedItemGroup,
                        touchedItemSubGroup,
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
                    warehouseLocationList.warehouseData[grpIndex].warehouseName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: qtyOrValCheck
                            ? "\nQty : ${formatAmount(warehouseLocationList.warehouseData[grpIndex].quantity)}"
                            : "\nVal : ${formatAmount(warehouseLocationList.warehouseData[grpIndex].quantity)}",
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

  Widget _inventoryLevel() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = inventoryGraphList.levelData.length;
    if (inventoryGraphList.levelData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? inventoryGraphList.levelData
              .map((data) => data.total)
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
                sideTitles: _bottomTitlesInventoryLevel,
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
            barGroups: _inventoryLevelChartData(inventoryGraphList.levelData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null &&
                    barTouchResponse.spot != null) {}
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
                    inventoryGraphList.levelData[grpIndex].itemName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\nMin-Level : ${formatAmount(inventoryGraphList.levelData[grpIndex].minLevel)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nMax-Level : ${formatAmount(inventoryGraphList.levelData[grpIndex].maxLevel)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nIn-Stock : ${formatAmount(inventoryGraphList.levelData[grpIndex].inStock)}",
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

  Widget _itemGroupWiseInventory() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemGroupList.itemGroupData.length;
    if (itemGroupList.itemGroupData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? itemGroupList.itemGroupData
              .map((data) => data.quantity)
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
            barGroups: _itemGroupWiseChartData(itemGroupList.itemGroupData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemGroup = touchedItemGroup == ""
                          ? itemGroupList
                                .itemGroupData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .groupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedAging,
                        touchedWarehouseLocation,
                        touchedItemGroup,
                        touchedItemSubGroup,
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
                    '${itemGroupList.itemGroupData[grpIndex].groupName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: qtyOrValCheck
                            ? "Qty: ${formatAmount(itemGroupList.itemGroupData[grpIndex].quantity)}"
                            : "Val: ${formatAmount(itemGroupList.itemGroupData[grpIndex].quantity)}",
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

  Widget _itemSubGroupWiseInventory() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemSubGroupList.itemSubGroupData.length;
    if (itemSubGroupList.itemSubGroupData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? itemSubGroupList.itemSubGroupData
              .map((data) => data.quantity)
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
                sideTitles: _bottomTitlesItemSubGroupWise,
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
            barGroups: _itemSubGroupWiseChartData(
              itemSubGroupList.itemSubGroupData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemSubGroup = touchedItemSubGroup == ""
                          ? itemSubGroupList
                                .itemSubGroupData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .subGroupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedAging,
                        touchedWarehouseLocation,
                        touchedItemGroup,
                        touchedItemSubGroup,
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
                    '${itemSubGroupList.itemSubGroupData[grpIndex].subGroupName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: qtyOrValCheck
                            ? "Qty: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].quantity)}"
                            : "Val: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].quantity)}",
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
