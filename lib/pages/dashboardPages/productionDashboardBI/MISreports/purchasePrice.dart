// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import '../../../../notificationService.dart';
import '../../ReportService.dart';
import '../../dashboard_card_ui.dart';

class MonthlySalesData {
  final String month;
  final int monthNumber;
  final double sumQuantity;
  final double sumRowTotal;

  const MonthlySalesData({
    required this.month,
    required this.monthNumber,
    required this.sumQuantity,
    required this.sumRowTotal,
  });

  double get averagePrice => sumQuantity == 0 ? 0.0 : sumRowTotal / sumQuantity;
}

class MonthlySalesDataList {
  final List<MonthlySalesData> list;

  MonthlySalesDataList({this.list = const []});
}

class ItemSubGroupBarData {
  final String itemSubGroup;
  final double sumQuantity;
  final double sumRowTotal;

  ItemSubGroupBarData({
    required this.itemSubGroup,
    required this.sumQuantity,
    required this.sumRowTotal,
  });

  double get averagePrice => sumQuantity == 0 ? 0.0 : sumRowTotal / sumQuantity;
}

class ItemSubGroupBarDataList {
  final List<ItemSubGroupBarData> list;
  ItemSubGroupBarDataList({required this.list});
}

class PurchasePriceMISProvider with ChangeNotifier {
  List<PurchaseList> _salesList = [];
  List<PurchaseList> get salesList => _salesList;
  void updatePurchaseList(List<PurchaseList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class PurchasePriceMIS extends StatefulWidget {
  const PurchasePriceMIS({super.key});

  @override
  State<PurchasePriceMIS> createState() => _PurchasePriceMISState();
}

class _PurchasePriceMISState extends State<PurchasePriceMIS> {
  final reportService = ReportService();
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  DateTime? lastMonthFromDate;
  bool chartDataLoaded = false;
  String? formattedFiscalYearStartDate;
  String? formattedDateNow;
  late Future<void> loadDataFuture;
  List<PurchaseList> purchasePrice = [];
  List<PurchaseList> purchasePriceTemp = [];
  List<InventoryList> inventory = [];
  InventoryAgingMISList inventoryAgingList = InventoryAgingMISList(
    agingData: [],
  );
  ItemSubGroupBarDataList itemSubGroupBarData = ItemSubGroupBarDataList(
    list: [],
  );
  MonthlySalesDataList monthlySalesData = MonthlySalesDataList();
  ItemGroupWiseInventoryMISList itemGroupList = ItemGroupWiseInventoryMISList(
    itemGroupData: [],
  );
  int touchedMonthIndex = 0;
  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
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

  void LoadDates() {
    currentDate = DateTime.now();

    int fiscalYearStartMonth = 4;

    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);
    lastMonthFromDate = DateTime(
      fiscalYearStartDate!.year,
      fiscalYearStartDate!.month - 1,
      1,
    );
    formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    touchedMonthIndex = currentDate!.month;
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

  SideTitles get _bottomTitlesItemGroupWise => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemSubGroupBarData> mData = itemSubGroupBarData.list;
      text = mData.elementAt(value.toInt()).itemSubGroup;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 10
              ? Text(
                  '${text.substring(0, 10)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesMonthWise => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlySalesData> mData = monthlySalesData.list;
      text = mData.elementAt(value.toInt()).month;
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

  List<BarChartGroupData> _monthWiseChartData(List<MonthlySalesData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.sumQuantity,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemGroupWiseChartData(
    List<ItemSubGroupBarData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.sumQuantity,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadPurchasePrice(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<PurchaseList> purchaseList = [];
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
        const apiUrl = '${ApiHelper.baseUrl}BicxoPurchaseList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<PurchaseList> newPurchaseList =
                (responseJson['responseData'] as List)
                    .map((item) => PurchaseList.fromJson(item))
                    .toList();

            purchaseList.addAll(newPurchaseList);
            fetchedCount = newPurchaseList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        purchasePrice = purchaseList;
        purchasePriceTemp = purchaseList;
        purchasePrice = purchaseList
            .where(
              (sale) =>
                  sale.type == "Item Purchase" &&
                  sale.itemGroup != "Fixed Assets" &&
                  sale.itemGroup != "General Products" &&
                  sale.itemGroup != "Finished Goods" &&
                  sale.invoiceType == "Purchase",
            )
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading purchase price.",
      );
    }
  }

  double toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return 0.0;
      // remove common thousands separators and currency symbols
      final cleaned = s
          .replaceAll(',', '')
          .replaceAll(RegExp(r'[^\d\.\-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _loadItemSubGroupBarData() async {
    List<ItemSubGroupBarData> subgroupDataList = [];
    Map<String, double> sumQuantityMap = {};
    Map<String, double> sumRowTotalMap = {};

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) {
        final cleaned = v.replaceAll(',', '').trim();
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    var productSalesList = purchasePrice.where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
          invoiceDate.isAtMost(currentDate!);
    });

    for (var product in productSalesList) {
      String subGroup = '';
      try {
        subGroup = (product.itemSubGroup).toString();
      } catch (_) {
        subGroup = '';
      }
      if (subGroup.trim().isEmpty) subGroup = 'Unknown';

      double qty = 0.0;
      double rowTotal = 0.0;
      try {
        qty = toDouble(product.quantity);
        rowTotal = toDouble(product.rowTotal);
      } catch (_) {
        // ignore and treat as zero
      }
      sumQuantityMap[subGroup] = (sumQuantityMap[subGroup] ?? 0.0) + qty;
      sumRowTotalMap[subGroup] = (sumRowTotalMap[subGroup] ?? 0.0) + rowTotal;
    }

    subgroupDataList = sumQuantityMap.keys.map((k) {
      final sumQty = sumQuantityMap[k] ?? 0.0;
      final sumRow = sumRowTotalMap[k] ?? 0.0;
      return ItemSubGroupBarData(
        itemSubGroup: k,
        sumQuantity: sumQty,
        sumRowTotal: sumRow,
      );
    }).toList();

    subgroupDataList.sort((a, b) => b.sumQuantity.compareTo(a.sumQuantity));

    itemSubGroupBarData = ItemSubGroupBarDataList(list: subgroupDataList);
  }

  Future<void> _loadMonthlySalesData() async {
    Map<int, double> sumQuantityMap = {};
    Map<int, double> sumRowTotalMap = {};

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) {
        final cleaned = v.replaceAll(',', '').trim();
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    // Filter the list to include only records within the desired date range.
    var productPurchaseList = purchasePrice.where((target) {
      try {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        // Ensure you have non-null date boundaries
        return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
            invoiceDate.isAtMost(currentDate!);
      } catch (e) {
        // Handle or log potential date parsing errors
        return false;
      }
    });

    for (var product in productPurchaseList) {
      try {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(product.invoiceDate);
        int month =
            invoiceDate.month; // Extracts month as an integer (1=Jan, 12=Dec)

        double qty = toDouble(product.quantity);
        double rowTotal = toDouble(product.rowTotal);

        sumQuantityMap[month] = (sumQuantityMap[month] ?? 0.0) + qty;
        sumRowTotalMap[month] = (sumRowTotalMap[month] ?? 0.0) + rowTotal;
      } catch (_) {}
    }

    const monthNames = [
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

    // Convert the aggregated map data into a list of MonthlySalesData objects.
    List<MonthlySalesData> monthlyDataList = sumQuantityMap.keys.map((
      monthKey,
    ) {
      return MonthlySalesData(
        monthNumber: monthKey,
        month:
            monthNames[monthKey -
                1], // Get month name from list (adjust for 0-based index)
        sumQuantity: sumQuantityMap[monthKey] ?? 0.0,
        sumRowTotal: sumRowTotalMap[monthKey] ?? 0.0,
      );
    }).toList();

    monthlyDataList.sort((a, b) => a.monthNumber.compareTo(b.monthNumber));

    monthlySalesData = MonthlySalesDataList(list: monthlyDataList);
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadPurchasePrice(userName, userLevel);
    await _loadItemSubGroupBarData();
    await _loadMonthlySalesData();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataClearFilter() async {
    setState(() {
      chartDataLoaded = false;
    });

    purchasePrice = List.from(purchasePriceTemp);

    await _loadItemSubGroupBarData();
    await _loadMonthlySalesData();

    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataWithFilter(int monthIndex) async {
    setState(() {
      chartDataLoaded = false;
    });

    purchasePrice = purchasePriceTemp.where((item) {
      try {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(item.invoiceDate);
        return invoiceDate.month == monthIndex;
      } catch (_) {
        return false;
      }
    }).toList();

    await _loadItemSubGroupBarData(); // Chart 1
    await _loadMonthlySalesData(); // Chart 2

    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> generatePurchasePriceExcel(BuildContext context) async {
    String reportTitle =
        'Production[MIS] - Purchase Price Analysis  $formattedFiscalYearStartDate - $formattedDateNow';

    if (touchedMonthIndex > 0) {
      final firstRecord = purchasePrice.firstWhere(
        (e) =>
            DateFormat('dd/MM/yyyy').parse(e.invoiceDate).month ==
            touchedMonthIndex,
      );

      final dt = DateFormat('dd/MM/yyyy').parse(firstRecord.invoiceDate);

      reportTitle =
          'Production[MIS] - Purchase Price Analysis - '
          '${DateFormat('MMM yyyy').format(dt)}';
    }
    await reportService.generateExcel(
      sheetName: 'PurchasePriceAnalysis',
      headers: [
        'Item Sub Group',
        'Purchase Qty.',
        'Avg Price',
        'Purchase Amt.',
      ],
      rows: itemSubGroupBarData.list
          .map(
            (dailyData) => [
              dailyData.itemSubGroup,
              dailyData.sumQuantity,
              dailyData.averagePrice,
              dailyData.sumRowTotal,
            ],
          )
          .toList(),
      fileName: 'purchase_price_analysis.xlsx',
      amountColumns: [2, 3, 4],
      addTotalRow: true,
      reportTitle: reportTitle,
    );
  }

  double getMaxValue(double maxValue, double divVal) {
    return (maxValue / divVal).ceil() * divVal;
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _monthlyHorizontalController = ScrollController();
  final ScrollController _itemGroupHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _monthlyHorizontalController.dispose();
    _itemGroupHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    return chartDataLoaded == true
        ? FinanceVerticalScroll(
            controller: _verticalScrollController,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 15),
                        Text(
                          "$formattedFiscalYearStartDate - $formattedDateNow",
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
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Month wise purchase summary ',
                    spacing: 10,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generatePurchasePriceExcel(context);
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _monthWisePurchase(),
                        const SizedBox(height: 15),
                        _itemGroupWisePurchase(),
                      ],
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
      position: const RelativeRect.fromLTRB(25.0, 100.0, 0.0, 0.0),
      elevation: 8.0,
      items: [
        const PopupMenuItem<String>(value: '1', child: Text('Remove Filter?')),
      ],
    ).then((value) {
      if (value == '1') {
        setState(() {
          loadDataFuture = loadDataClearFilter();
        });
      }
    });
  }

  Widget _itemGroupWisePurchase() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemSubGroupBarData.list.length;
    if (itemSubGroupBarData.list.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? itemSubGroupBarData.list
              .map((data) => data.sumQuantity)
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
              maxY: getMaxValue(maxAmount, 500000),
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
              barGroups: _itemGroupWiseChartData(itemSubGroupBarData.list),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {}
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
                      itemSubGroupBarData.list[grpIndex].itemSubGroup,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "\nPurchase Qty : ${formatAmount(itemSubGroupBarData.list[grpIndex].sumQuantity)}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nAverage Price : ${(itemSubGroupBarData.list[grpIndex].averagePrice).toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nPurchase Amount : ${formatAmount(itemSubGroupBarData.list[grpIndex].sumRowTotal)}",
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

  Widget _monthWisePurchase() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlySalesData.list.length;
    if (monthlySalesData.list.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? monthlySalesData.list
              .map((data) => data.sumQuantity)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _monthlyHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxAmount, 1000000),
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
                  sideTitles: _bottomTitlesMonthWise,
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
              barGroups: _monthWiseChartData(monthlySalesData.list),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      int monthIndex = monthlySalesData
                          .list[barTouchResponse.spot!.spot.x.toInt()]
                          .monthNumber;

                      if (touchedMonthIndex == monthIndex) {
                        touchedMonthIndex = 0;
                        await loadDataClearFilter();
                      } else {
                        touchedMonthIndex = monthIndex;
                        await loadDataWithFilter(monthIndex);
                      }

                      setState(() {});
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
                      '${monthlySalesData.list[grpIndex].month}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Purchase Amount: ${formatAmount(monthlySalesData.list[grpIndex].sumRowTotal)}\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Average Price: ${(monthlySalesData.list[grpIndex].averagePrice).toStringAsFixed(2)}\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Purchase Quantity: ${formatAmount(monthlySalesData.list[grpIndex].sumQuantity)}",
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
}
