// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';
import 'package:optima/pages/dashboardPages/pdf_helper_web.dart';

import '../../../notificationService.dart';

class InventoryMovementAnalysis extends StatefulWidget {
  const InventoryMovementAnalysis({super.key});

  @override
  State<InventoryMovementAnalysis> createState() =>
      _InventoryMovementAnalysisState();
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
List<InventoryMovementList> inventoryMovement = [];

double totalInward = 0;
double totalOutward = 0;
double closingInventory = 0;
double openingInventory = 0;

ItemWiseInventoryMovementList itemList = ItemWiseInventoryMovementList(
  itemData: [],
);
ItemGroupWiseInventoryMovementList itemGroupList =
    ItemGroupWiseInventoryMovementList(itemGroupData: []);
ItemSubGroupWiseInventoryMovementList itemSubGroupList =
    ItemSubGroupWiseInventoryMovementList(itemSubGroupData: []);

String touchedItem = "";
String touchedItemGroup = "";
String touchedItemSubGroup = "";

double selectedChart = 0;

bool qtyOrValCheck = true;

class InventoryMovementAnalysisProvider with ChangeNotifier {
  List<InventoryMovementList> _salesList = [];
  List<InventoryMovementList> get salesList => _salesList;
  void updateInventoryMovementList(List<InventoryMovementList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class _InventoryMovementAnalysisState extends State<InventoryMovementAnalysis> {
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

  SideTitles get _bottomTitlesItemWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemWiseInventoryMovementData> mData = itemList.itemData;
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
      List<ItemGroupWiseInventoryMovementData> mData =
          itemGroupList.itemGroupData;
      text = mData.elementAt(value.toInt()).itemGroupName;
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
      List<ItemSubGroupWiseInventoryMovementData> mData =
          itemSubGroupList.itemSubGroupData;
      text = mData.elementAt(value.toInt()).itemSubGroupName;
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

  List<BarChartGroupData> _itemWiseAnalysisChartData(
    List<ItemWiseInventoryMovementData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.cbQuantity,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemGroupWiseChartData(
    List<ItemGroupWiseInventoryMovementData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.cbQuantity,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemSubGroupWiseChartData(
    List<ItemSubGroupWiseInventoryMovementData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.cbQuantity,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadInventoryMovement(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<InventoryMovementList> salesList = [];
    try {
      do {
        var body = {
          "FromDate": formatDate(currentMonthFromDate!),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoStockMovementList';
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
            List<InventoryMovementList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => InventoryMovementList.fromJson(item))
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
            .read<InventoryMovementAnalysisProvider>()
            .updateInventoryMovementList(salesList);
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          inventoryMovement = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          inventoryMovement = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          inventoryMovement = salesList.toList();
        } else {
          inventoryMovement = salesList.toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading inventory movement data.",
      );
    }
  }

  Future<void> _loadItemWiseInventory(
    String item,
    String itemGroup,
    String itemSubGroup,
  ) async {
    var inventoryList = inventoryMovement;

    String itemName = "";
    double obQtySum = 0.00;
    double inQtySum = 0.00;
    double outQtySum = 0.00;
    double cbQtySum = 0.00;
    double cbValSum = 0.00;
    List<ItemWiseInventoryMovementData> itemData = [];
    Set<String> processed = {};

    inventoryList = filterInventoryList(
      inventoryList.cast<InventoryMovementList>().toList(),
      item: item,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
    );

    for (var item in inventoryList) {
      if (!processed.contains(item.itemDescription)) {
        itemName = item.itemDescription;
        for (var target in inventoryList.where(
          (prdelement) => prdelement.itemDescription == itemName,
        )) {
          // obqty
          // inQty
          // outQt
          double obQty = qtyOrValCheck
              ? double.tryParse(target.obQty) ?? 0
              : double.tryParse(target.obVal) ?? 0;
          double inQty = qtyOrValCheck
              ? double.tryParse(target.inQty) ?? 0
              : double.tryParse(target.inVal) ?? 0;
          double outQty = qtyOrValCheck
              ? double.tryParse(target.outQty) ?? 0
              : double.tryParse(target.outVal) ?? 0;
          double cbQty = qtyOrValCheck
              ? double.tryParse(target.cbQty) ?? 0
              : double.tryParse(target.cbVal) ?? 0;
          double cbVal = qtyOrValCheck
              ? double.tryParse(target.cbVal) ?? 0
              : double.tryParse(target.cbQty) ?? 0;
          obQtySum += obQty;
          inQtySum += inQty;
          outQtySum += outQty;
          cbQtySum += cbQty;
          cbValSum += cbVal;
        }

        itemData.add(
          ItemWiseInventoryMovementData(
            itemName: itemName,
            obQuantity: obQtySum,
            inQuantity: inQtySum,
            outQuantity: outQtySum,
            cbQuantity: cbQtySum,
            cbValue: cbValSum,
          ),
        );
        processed.add(item.itemDescription);
      }
      obQtySum = 0;
      inQtySum = 0;
      outQtySum = 0;
      cbQtySum = 0;
      cbValSum = 0;
      itemName = "";
    }

    itemData.sort((a, b) => b.cbQuantity.compareTo(a.cbQuantity));

    for (var item in inventoryMovement) {
      double? inward = qtyOrValCheck
          ? double.tryParse(item.inQty) ?? 0
          : double.tryParse(item.inVal) ?? 0;
      double? outward = qtyOrValCheck
          ? double.tryParse(item.outQty) ?? 0
          : double.tryParse(item.outVal) ?? 0;
      double? closing = qtyOrValCheck
          ? double.tryParse(item.cbQty) ?? 0
          : double.tryParse(item.cbVal) ?? 0;
      double? opening = qtyOrValCheck
          ? double.tryParse(item.obQty) ?? 0
          : double.tryParse(item.obVal) ?? 0;
      totalInward += inward;
      totalOutward += outward;
      closingInventory += closing;
      openingInventory += opening;
    }

    itemList = ItemWiseInventoryMovementList(itemData: itemData);

    // totalInventory = itemGroupList.itemGroupData.fold(
    //     0, (prev, elem) => prev + itemGroupList.itemGroupData.first.quantity);
  }

  Future<void> _loadItemGroupWiseInventory(
    String item,
    String itemGroup,
    String itemSubGroup,
  ) async {
    var inventoryList = inventoryMovement;

    String itemGroupName = "";
    double obQtySum = 0.00;
    double inQtySum = 0.00;
    double outQtySum = 0.00;
    double cbQtySum = 0.00;
    double cbValSum = 0.00;
    List<ItemGroupWiseInventoryMovementData> itemData = [];
    Set<String> processed = {};

    inventoryList = filterInventoryList(
      inventoryList.cast<InventoryMovementList>().toList(),
      item: item,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
    );

    for (var item in inventoryList) {
      if (!processed.contains(item.groupName)) {
        itemGroupName = item.groupName;
        for (var target in inventoryList.where(
          (prdelement) => prdelement.groupName == itemGroupName,
        )) {
          double obQty = qtyOrValCheck
              ? double.tryParse(target.obQty) ?? 0
              : double.tryParse(target.obVal) ?? 0;
          double inQty = qtyOrValCheck
              ? double.tryParse(target.inQty) ?? 0
              : double.tryParse(target.inVal) ?? 0;
          double outQty = qtyOrValCheck
              ? double.tryParse(target.outQty) ?? 0
              : double.tryParse(target.outVal) ?? 0;
          double cbQty = qtyOrValCheck
              ? double.tryParse(target.cbQty) ?? 0
              : double.tryParse(target.cbVal) ?? 0;
          double cbVal = qtyOrValCheck
              ? double.tryParse(target.cbVal) ?? 0
              : double.tryParse(target.cbQty) ?? 0;
          obQtySum += obQty;
          inQtySum += inQty;
          outQtySum += outQty;
          cbQtySum += cbQty;
          cbValSum += cbVal;
        }

        itemData.add(
          ItemGroupWiseInventoryMovementData(
            itemGroupName: itemGroupName,
            obQuantity: obQtySum,
            inQuantity: inQtySum,
            outQuantity: outQtySum,
            cbQuantity: cbQtySum,
            cbValue: cbValSum,
          ),
        );
        processed.add(item.groupName);
      }
      obQtySum = 0;
      inQtySum = 0;
      outQtySum = 0;
      cbQtySum = 0;
      cbValSum = 0;
      itemGroupName = "";
    }

    itemData.sort((a, b) => b.cbQuantity.compareTo(a.cbQuantity));

    itemGroupList = ItemGroupWiseInventoryMovementList(itemGroupData: itemData);

    // totalInventory = itemGroupList.itemGroupData.fold(
    //     0, (prev, elem) => prev + itemGroupList.itemGroupData.first.quantity);
  }

  Future<void> _loadItemSubGroupWiseInventory(
    String item,
    String itemGroup,
    String itemSubGroup,
  ) async {
    var inventoryList = inventoryMovement;

    String itemGroupName = "";
    double obQtySum = 0.00;
    double inQtySum = 0.00;
    double outQtySum = 0.00;
    double cbQtySum = 0.00;
    double cbValSum = 0.00;
    List<ItemSubGroupWiseInventoryMovementData> itemData = [];
    Set<String> processed = {};

    inventoryList = filterInventoryList(
      inventoryList.cast<InventoryMovementList>().toList(),
      item: item,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
    );

    for (var item in inventoryList) {
      if (!processed.contains(item.itemSubGroup)) {
        itemGroupName = item.itemSubGroup;
        for (var target in inventoryList.where(
          (prdelement) => prdelement.itemSubGroup == itemGroupName,
        )) {
          double obQty = qtyOrValCheck
              ? double.tryParse(target.obQty) ?? 0
              : double.tryParse(target.obVal) ?? 0;
          double inQty = qtyOrValCheck
              ? double.tryParse(target.inQty) ?? 0
              : double.tryParse(target.inVal) ?? 0;
          double outQty = qtyOrValCheck
              ? double.tryParse(target.outQty) ?? 0
              : double.tryParse(target.outVal) ?? 0;
          double cbQty = qtyOrValCheck
              ? double.tryParse(target.cbQty) ?? 0
              : double.tryParse(target.cbVal) ?? 0;
          double cbVal = qtyOrValCheck
              ? double.tryParse(target.cbVal) ?? 0
              : double.tryParse(target.cbQty) ?? 0;
          obQtySum += obQty;
          inQtySum += inQty;
          outQtySum += outQty;
          cbQtySum += cbQty;
          cbValSum += cbVal;
        }

        itemData.add(
          ItemSubGroupWiseInventoryMovementData(
            itemSubGroupName: itemGroupName,
            obQuantity: obQtySum,
            inQuantity: inQtySum,
            outQuantity: outQtySum,
            cbQuantity: cbQtySum,
            cbValue: cbValSum,
          ),
        );
        processed.add(item.itemSubGroup);
      }
      obQtySum = 0;
      inQtySum = 0;
      outQtySum = 0;
      cbQtySum = 0;
      cbValSum = 0;
      itemGroupName = "";
    }

    itemData.sort((a, b) => b.cbQuantity.compareTo(a.cbQuantity));

    itemSubGroupList = ItemSubGroupWiseInventoryMovementList(
      itemSubGroupData: itemData,
    );
    // totalInventory = itemGroupList.itemGroupData.fold(
    //     0, (prev, elem) => prev + itemGroupList.itemGroupData.first.quantity);
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadInventoryMovement(userName, userLevel);
    await _loadItemWiseInventory("", "", "");
    await _loadItemGroupWiseInventory("", "", "");
    await _loadItemSubGroupWiseInventory("", "", "");
    chartDataLoaded = true;
  }

  Future<void> loadQuantityOrValue(String selectedUser) async {
    totalInward = 0;
    totalOutward = 0;
    closingInventory = 0;
    openingInventory = 0;
    await _loadItemWiseInventory("", "", "");
    await _loadItemGroupWiseInventory("", "", "");
    await _loadItemSubGroupWiseInventory("", "", "");
    chartDataLoaded = true;
  }

  List<InventoryMovementList> filterInventoryList(
    List<InventoryMovementList> collectionTargetList, {
    String? item,
    String? itemGroup,
    String? itemSubGroup,
  }) {
    List<InventoryMovementList> filteredCollectionTargetList = [];

    for (var target in collectionTargetList) {
      if ((item == null || item.isEmpty || target.itemDescription == item) &&
          (itemGroup == null ||
              itemGroup.isEmpty ||
              target.groupName == itemGroup) &&
          (itemSubGroup == null ||
              itemSubGroup.isEmpty ||
              target.itemSubGroup == itemSubGroup)) {
        filteredCollectionTargetList.add(target);
      }
    }
    return filteredCollectionTargetList;
  }

  Future<void> loadDataWithFilter(
    String? item,
    String? itemGroup,
    String? itemSubGroup,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    await _loadItemWiseInventory(item!, itemGroup!, itemSubGroup!);
    await _loadItemGroupWiseInventory(item, itemGroup, itemSubGroup);
    await _loadItemSubGroupWiseInventory(item, itemGroup, itemSubGroup);
    chartDataLoaded = true;
  }

  Future<void> removeFilter() async {
    clearVariables();
    LoadDates();
    await _loadItemWiseInventory("", "", "");
    await _loadItemGroupWiseInventory("", "", "");
    await _loadItemSubGroupWiseInventory("", "", "");
    chartDataLoaded = true;
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;
      itemList = ItemWiseInventoryMovementList(itemData: []);
      itemGroupList = ItemGroupWiseInventoryMovementList(itemGroupData: []);
      itemSubGroupList = ItemSubGroupWiseInventoryMovementList(
        itemSubGroupData: [],
      );
      touchedItem = "";
      touchedItemGroup = "";
      touchedItemSubGroup = "";
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoaded = false;
      itemList = ItemWiseInventoryMovementList(itemData: []);
      itemGroupList = ItemGroupWiseInventoryMovementList(itemGroupData: []);
      itemSubGroupList = ItemSubGroupWiseInventoryMovementList(
        itemSubGroupData: [],
      );
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

  Future<void> generateItemWiseExcel(ItemWiseInventoryMovementList list) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Item Name', 'Qty']));
      for (var monthlyData in list.itemData) {
        sheet.appendRow(
          toCellRow([monthlyData.itemName, monthlyData.outQuantity]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('itemWiseAnalysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemWiseAnalysis.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating item wise excel.",
      );
    }
  }

  Future<void> generateItemWisePDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Item Wise Analysis',
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
                      'Qty',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in itemList.itemData)
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
                        data.outQuantity.toString(),
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
        final file = File('$storageDir/itemWiseAnalysis.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating item wise pdf.",
      );
    }
  }

  Future<void> generateItemGroupWiseExcel(
    ItemGroupWiseInventoryMovementList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Item Group', 'Qty']));
      for (var monthlyData in list.itemGroupData) {
        sheet.appendRow(
          toCellRow([monthlyData.itemGroupName, monthlyData.outQuantity]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('itemGroupWiseAnalysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemGroupWiseAnalysis.xlsx');
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

  Future<void> generateItemGroupWisePDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Item Group Wise Analysis',
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
                        data.itemGroupName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.outQuantity.toString(),
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
        final file = File('$storageDir/itemWiseAnalysis.pdf');
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

  Future<void> generateItemSubGroupWiseExcel(
    ItemSubGroupWiseInventoryMovementList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Item Sub Group', 'Qty']));
      for (var monthlyData in list.itemSubGroupData) {
        sheet.appendRow(
          toCellRow([monthlyData.itemSubGroupName, monthlyData.outQuantity]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('itemSubGroupWiseAnalysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemSubGroupWiseAnalysis.xlsx');
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

  Future<void> generateItemSubGroupWisePDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Item Sub Group Wise Analysis',
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
                        data.itemSubGroupName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.outQuantity.toString(),
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
        final file = File('$storageDir/itemWiseAnalysis.pdf');
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

  void toggleCheckbox() {
    setState(() {
      chartDataLoaded = false;
      loadData("");
      qtyOrValCheck = !qtyOrValCheck;
    });
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Showing Data:"),
                      const SizedBox(width: 10),
                      const Text("Quantity"),
                      Checkbox(
                        checkColor: Colors.white,
                        value: qtyOrValCheck,
                        onChanged: (_) => toggleCheckbox(),
                      ),
                      const SizedBox(width: 5),
                      const Text("Value"),
                      Checkbox(
                        checkColor: Colors.white,
                        value: !qtyOrValCheck,
                        onChanged: (_) => toggleCheckbox(),
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
                          width: 145,
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
                                const Text(
                                  'Open Inventory',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  formatAmount(openingInventory),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 145,
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
                                const Text(
                                  'Total Inwards',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  formatAmount(totalInward),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 145,
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
                                const Text(
                                  'Total Outwards',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  formatAmount(totalOutward),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 145,
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
                                const Text(
                                  'Closing Inventory',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  formatAmount(closingInventory),
                                  style: const TextStyle(fontSize: 12),
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
                          "Item Wise Analysis",
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
                                    generateItemWiseExcel(itemList);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemWisePDF();
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
                  child: _itemWiseAnalysis(),
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
                                  setState(() {
                                    generateItemGroupWiseExcel(itemGroupList);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemGroupWisePDF();
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
                                  setState(() {
                                    generateItemSubGroupWiseExcel(
                                      itemSubGroupList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemSubGroupWisePDF();
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
                  child: _itemSubGroupWiseInventory(),
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

  Widget _itemWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemList.itemData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? itemList.itemData
              .map((data) => data.cbQuantity)
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
                sideTitles: _bottomTitlesItemWiseAnalysis,
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
            barGroups: _itemWiseAnalysisChartData(itemList.itemData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItem = touchedItem == ""
                          ? itemList
                                .itemData[barTouchResponse.spot!.spot.x.toInt()]
                                .itemName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedItem,
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
                    '${itemList.itemData[grpIndex].itemName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: qtyOrValCheck
                            ? "OB Qty: ${formatAmount(itemList.itemData[grpIndex].obQuantity)}\n"
                            : "OB Val: ${formatAmount(itemList.itemData[grpIndex].obQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "In Qty: ${formatAmount(itemList.itemData[grpIndex].inQuantity)}\n"
                            : "In Val: ${formatAmount(itemList.itemData[grpIndex].inQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "Out Qty: ${formatAmount(itemList.itemData[grpIndex].outQuantity)}\n"
                            : "Out Val: ${formatAmount(itemList.itemData[grpIndex].outQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "CB Qty: ${formatAmount(itemList.itemData[grpIndex].cbQuantity)}\n"
                            : "CB Val: ${formatAmount(itemList.itemData[grpIndex].cbQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "CB Val: ${formatAmount(itemList.itemData[grpIndex].cbValue)}\n"
                            : "CB Qty: ${formatAmount(itemList.itemData[grpIndex].cbValue)}\n",
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
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? itemGroupList.itemGroupData
              .map((data) => data.cbQuantity)
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
                                .itemGroupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedItem,
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
                    '${itemGroupList.itemGroupData[grpIndex].itemGroupName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: qtyOrValCheck
                            ? "OB Qty: ${formatAmount(itemGroupList.itemGroupData[grpIndex].obQuantity)}\n"
                            : "OB Val: ${formatAmount(itemGroupList.itemGroupData[grpIndex].obQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "In Qty: ${formatAmount(itemGroupList.itemGroupData[grpIndex].inQuantity)}\n"
                            : "In Val: ${formatAmount(itemGroupList.itemGroupData[grpIndex].inQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "Out Qty: ${formatAmount(itemGroupList.itemGroupData[grpIndex].outQuantity)}\n"
                            : "Out Val: ${formatAmount(itemGroupList.itemGroupData[grpIndex].outQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "CB Qty: ${formatAmount(itemGroupList.itemGroupData[grpIndex].cbQuantity)}\n"
                            : "CB Val: ${formatAmount(itemGroupList.itemGroupData[grpIndex].cbQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "CB Val: ${formatAmount(itemGroupList.itemGroupData[grpIndex].cbValue)}"
                            : "CB Qty: ${formatAmount(itemGroupList.itemGroupData[grpIndex].cbValue)}\n",
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
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? itemGroupList.itemGroupData
              .map((data) => data.cbQuantity)
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
                                .itemSubGroupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedItem,
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
                    '${itemSubGroupList.itemSubGroupData[grpIndex].itemSubGroupName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: qtyOrValCheck
                            ? "OB Qty: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].obQuantity)}\n"
                            : "OB Val: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].obQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "In Qty: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].inQuantity)}\n"
                            : "In Val: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].inQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "Out Qty: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].outQuantity)}\n"
                            : "Out Val: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].outQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "CB Qty: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].cbQuantity)}\n"
                            : "CB Val: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].cbQuantity)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: qtyOrValCheck
                            ? "CB Val: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].cbValue)}"
                            : "CB Qty: ${formatAmount(itemSubGroupList.itemSubGroupData[grpIndex].cbValue)}",
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
