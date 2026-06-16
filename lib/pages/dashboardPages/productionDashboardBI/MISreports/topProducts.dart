// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
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

class TopProductsMISProvider with ChangeNotifier {
  List<JobCardDetails> _salesList = [];
  List<JobCardDetails> get salesList => _salesList;
  void updateInventoryList(List<JobCardDetails> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class TopProductsPage extends StatefulWidget {
  const TopProductsPage({super.key});

  @override
  State<TopProductsPage> createState() => _TopProductsPageState();
}

class _TopProductsPageState extends State<TopProductsPage> {
  final reportService = ReportService();
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  DateTime? lastMonthFromDate;
  bool chartDataLoaded = false;
  String? formattedFiscalYearStartDate;
  String? formattedDateNow;
  late Future<void> loadDataFuture;
  List<ItemCostList> itemCostList = [];
  List<JobCardDetails> jobCardDetails = [];
  List<JobCardDetails> jobCardDetailsTemp = [];
  ProductBarDataList productBarData = ProductBarDataList(list: []);
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

  SideTitles get _bottomTitlesTopProducts => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ProductBarData> mData = productBarData.list;
      text = mData.elementAt(value.toInt()).fgProductName;
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

  List<BarChartGroupData> _TopProductsChartData(List<ProductBarData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.productionQty,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadJobCardDetails(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<JobCardDetails> jobCardList = [];
    try {
      do {
        var body = {
          "Index": index.toString(),
          "Limit": limit.toString(),
          "ReportType": "Top",
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl =
            '${ApiHelper.baseUrl}CRM_StandardVsActualConsumptionReport';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<JobCardDetails> newJobCardList =
                (responseJson['responseData'] as List)
                    .map((item) => JobCardDetails.fromJson(item))
                    .toList();

            jobCardList.addAll(newJobCardList);
            fetchedCount = newJobCardList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        jobCardDetails = jobCardList.toList();
        jobCardDetailsTemp = jobCardList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading job card details.",
      );
    }
  }

  Future<void> _loadItemCost(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<ItemCostList> tmpItemCostList = [];
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
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<ItemCostList> newItemCostList =
                (responseJson['responseData'] as List)
                    .map((item) => ItemCostList.fromJson(item))
                    .toList();

            tmpItemCostList.addAll(newItemCostList);
            fetchedCount = newItemCostList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        itemCostList = tmpItemCostList;
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading item cost.",
      );
    }
  }

  Future<void> _loadProductBarData(
    List<JobCardDetails> jobCardDetailsList,
  ) async {
    Map<String, double> sumProductionQtyMap = {};
    Map<String, double> itemCostMap = {};
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) {
        final cleaned = v.replaceAll(',', '').trim();
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    for (var detail in jobCardDetailsList) {
      String productName = detail.fgProductName;

      if (productName.trim().isEmpty) {
        productName = 'Unknown';
      }

      double qty = toDouble(detail.completedQty);

      sumProductionQtyMap[productName] =
          (sumProductionQtyMap[productName] ?? 0.0) + qty;
    }

    for (var item in itemCostList) {
      String productName = item.itemName;
      if (productName.trim().isEmpty) {
        productName = 'Unknown';
      }

      double cost = toDouble(item.itemCost);
      itemCostMap[productName] = cost;
    }

    List<ProductBarData> productDataList = sumProductionQtyMap.keys.map((
      productNameKey,
    ) {
      return ProductBarData(
        fgProductName: productNameKey,
        bomQty: 0,
        bomCost: itemCostMap[productNameKey] ?? 0.0,
        productionQty: sumProductionQtyMap[productNameKey] ?? 0.0,
        actualCost:
            (itemCostMap[productNameKey] ?? 0.0) *
            (sumProductionQtyMap[productNameKey] ?? 0.0),
        deviation: 0,
        percentage: 0,
      );
    }).toList();

    productDataList.sort((a, b) => b.productionQty.compareTo(a.productionQty));

    productBarData = ProductBarDataList(list: productDataList);
  }

  Future<void> generateTopProductsExcel(BuildContext context) async {
    String reportTitle =
        'Production[MIS] - Top Products  $formattedFiscalYearStartDate - $formattedDateNow';

    // if (touchedMonthIndex > 0) {
    //   final firstRecord = purchasePrice.firstWhere(
    //     (e) =>
    //         DateFormat('dd/MM/yyyy').parse(e.invoiceDate).month ==
    //         touchedMonthIndex,
    //   );

    //   final dt = DateFormat('dd/MM/yyyy').parse(firstRecord.invoiceDate);

    //   reportTitle =
    //       'Production[MIS] - Purchase Price Analysis - '
    //       '${DateFormat('MMM yyyy').format(dt)}';
    // }
    await reportService.generateExcel(
      sheetName: 'TopProductsAnalysis',
      headers: ['Product Name', 'BOM Cost', 'Production Qty.', 'Actual Cost'],
      rows: productBarData.list
          .map(
            (dailyData) => [
              dailyData.fgProductName,
              dailyData.bomCost,
              dailyData.productionQty,
              dailyData.actualCost,
            ],
          )
          .toList(),
      fileName: 'top_products_analysis.xlsx',
      amountColumns: [2, 3, 4],
      addTotalRow: true,
      reportTitle: reportTitle,
    );
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadJobCardDetails(userName, userLevel);
    await _loadItemCost(userName, userLevel);
    await _loadProductBarData(jobCardDetails);
    chartDataLoaded = true;
  }

  Future<void> loadDataClearFilter() async {
    setState(() {
      chartDataLoaded = false;
    });

    jobCardDetails = List.from(jobCardDetailsTemp);

    await _loadProductBarData(jobCardDetails);

    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataWithFilter(int monthIndex) async {
    setState(() {
      chartDataLoaded = false;
    });

    // purchasePrice = purchasePriceTemp.where((item) {
    //   try {
    //     DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(item.invoiceDate);
    //     return invoiceDate.month == monthIndex;
    //   } catch (_) {
    //     return false;
    //   }
    // }).toList();

    await _loadProductBarData(jobCardDetails);

    setState(() {
      chartDataLoaded = true;
    });
  }

  double getMaxValue(double maxValue, double divVal) {
    return (maxValue / divVal).ceil() * divVal;
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

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
    _horizontalController.dispose();
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
                  ],
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Top Products-Standard vs Actual Consumption.',
                    spacing: 10,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateTopProductsExcel(context);
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _topProducts(),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _topProducts() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = productBarData.list.length;
    if (productBarData.list.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? productBarData.list
              .map((data) => data.productionQty)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _horizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxAmount, 100),
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
                  sideTitles: _bottomTitlesTopProducts,
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
              barGroups: _TopProductsChartData(productBarData.list),
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
                      productBarData.list[grpIndex].fgProductName,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        //Below tooltips commented as per Prabhakar on 15-06-2026

                        // TextSpan(
                        //   text:
                        //       "\nBOM Qty : ${formatAmount(productBarData.list[grpIndex].bomQty)}",
                        //   style: const TextStyle(
                        //     color: Colors.black, //widget.touchedBarColor,
                        //     fontSize: 12,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                        TextSpan(
                          text:
                              "\nBOM Cost : ${productBarData.list[grpIndex].bomCost.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nProduction Qty. : ${productBarData.list[grpIndex].productionQty}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nProduction Value : ${productBarData.list[grpIndex].actualCost.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // TextSpan(
                        //   text:
                        //       "\nDeviation : ${formatAmount(productBarData.list[grpIndex].deviation)}",
                        //   style: const TextStyle(
                        //     color: Colors.black, //widget.touchedBarColor,
                        //     fontSize: 12,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                        // TextSpan(
                        //   text:
                        //       "\nPercentage : ${formatAmount(productBarData.list[grpIndex].percentage)}",
                        //   style: const TextStyle(
                        //     color: Colors.black, //widget.touchedBarColor,
                        //     fontSize: 12,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
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
