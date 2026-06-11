// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import '../ReportService.dart';
import '../dashboard_card_ui.dart';

final reportService = ReportService();

class JobCartEntryForAlternateMaterials extends StatefulWidget {
  const JobCartEntryForAlternateMaterials({super.key});

  @override
  State<JobCartEntryForAlternateMaterials> createState() =>
      _JobCartEntryForAlternateMaterialsState();
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

MonthWiseAnalysisJobCardList monthData = MonthWiseAnalysisJobCardList(
  monthData: [],
);
BranchWiseJobCardList branchWiseData = BranchWiseJobCardList(
  branchWiseData: [],
);
ItemGroupWiseAnalysisJobCardList itemGroupData =
    ItemGroupWiseAnalysisJobCardList(itemGroupData: []);
ItemSubGroupWiseAnalysisJobCardList itemSubGroupData =
    ItemSubGroupWiseAnalysisJobCardList(itemSubGroupData: []);
ItemWiseAnalysisJobCardList itemData = ItemWiseAnalysisJobCardList(
  itemData: [],
);
WarehouseWiseAnalysisJobCardList warehouseData =
    WarehouseWiseAnalysisJobCardList(warehouseData: []);

List<ProductionList> jobCardProduction = [];

bool chartDataLoaded = false;
int touchedMonthIndex = 0;
String touchedMonth = "";
String touchedItemCode = "";
String touchedItemGroup = "";
String touchedItemSubGroup = "";
String touchedWarehouse = "";
double selectedChart = 0;

class JobCardEntryProvider with ChangeNotifier {
  List<ProductionList> _salesList = [];
  List<ProductionList> get salesList => _salesList;
  void updateProductionList(List<ProductionList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class _JobCartEntryForAlternateMaterialsState
    extends State<JobCartEntryForAlternateMaterials> {
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  bool showDrillDownChart = false;
  int touchedIndex = -1;

  String? formattedFiscalYearStartDate;
  String? formattedQuarterStartDate;
  String? formattedQuarterLastDate;
  String? formattedDateNow;
  String? formattedDateFirstOfLastMonth;
  String? formattedDateLastOfLastMonth;
  String? formattedDateFirstOfThisMonth;

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

  String formatAmountChartAxis(double amount) {
    if (amount >= 10000000) {
      // Amount in crores
      return '${(amount / 10000000).toString()} Cr';
    } else if (amount >= 100000) {
      // Amount in lakhs
      return '${(amount / 100000).toString()} L';
    } else {
      // Amount in thousands
      return '${(amount / 1000).toString()} K';
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
      case 3:
        return const Color(0xFFFF4A4C);
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

    formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    formattedQuarterStartDate = DateFormat(
      'dd/MM/yy',
    ).format(currentQuarterFromDate!);
    formattedQuarterLastDate = DateFormat(
      'dd/MM/yy',
    ).format(currentQuarterToDate!);
    formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    formattedDateFirstOfLastMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month - 1, 1));
    formattedDateLastOfLastMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month, 0));
    formattedDateFirstOfThisMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month, 1));
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String leftDouble = "";
      leftDouble = formatAmountChartAxis(value);
      return Text(leftDouble, style: const TextStyle(fontSize: 12));
    },
  );

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
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

  SideTitles get _bottomTitlesMonthWiseQtyAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthWiseAnalysisJobCardData> mData = monthData.monthData;
      text = mData.elementAt(value.toInt()).monthName;
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

  SideTitles get _bottomTitlesItemDescriptionWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemWiseAnalysisJobCardData> mData = itemData.itemData;
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

  SideTitles get _bottomTitlesItemGroupWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemGroupWiseAnalysisJobCardData> mData =
          itemGroupData.itemGroupData;
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

  SideTitles get _bottomTitlesItemSubGroupWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemSubGroupWiseAnalysisJobCardData> mData =
          itemSubGroupData.itemSubGroupData;
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

  SideTitles get _bottomTitlesWarehouseWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<WarehouseWiseAnalysisJobCardData> mData =
          warehouseData.warehouseData;
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

  List<PieChartSectionData> showingSectionsBranchWise() {
    final List<PieChartSectionData> sections = [];
    for (final categoryData in branchWiseData.branchWiseData) {
      final fontSize = touchedIndex >= 1 ? 12.0 : 11.0;
      final radius = touchedIndex >= 1 ? 80.0 : 75.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final sectionData = PieChartSectionData(
        color: getCategoryColor(categoryData.branchId),
        value: categoryData.percentage,
        title: '${categoryData.percentage.toStringAsFixed(2)} %',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
          shadows: shadows,
        ),
      );
      sections.add(sectionData);
    }
    return sections;
  }

  List<BarChartGroupData> _monthWiseQtyAnalysisChartData(
    List<MonthWiseAnalysisJobCardData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.production,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemWiseAnalysisChartData(
    List<ItemWiseAnalysisJobCardData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                toY: chartData.lineTotal,
                width: 10,
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
              ),
              BarChartRodData(
                toY: chartData.quantity,
                width: 10,
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemGroupWiseAnalysisChartData(
    List<ItemGroupWiseAnalysisJobCardData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                toY: chartData.lineTotal,
                width: 15,
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
              ),
              BarChartRodData(
                toY: chartData.quantity,
                width: 15,
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemSubGroupWiseAnalysisChartData(
    List<ItemSubGroupWiseAnalysisJobCardData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                toY: chartData.lineTotal,
                width: 15,
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
              ),
              BarChartRodData(
                toY: chartData.quantity,
                width: 15,
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _warehouseWiseAnalysisChartData(
    List<WarehouseWiseAnalysisJobCardData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                toY: chartData.lineTotal,
                width: 15,
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
              ),
              BarChartRodData(
                toY: chartData.quantity,
                width: 15,
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadProductionList(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<ProductionList> salesList = [];
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
        const apiUrl = '${ApiHelper.baseUrl}BicxoGoodsProducedList';
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
            List<ProductionList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => ProductionList.fromJson(item))
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
        jobCardProduction = salesList;
        context.read<JobCardEntryProvider>().updateProductionList(salesList);
        if (int.parse(UserLevel) == 5) {
          jobCardProduction = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          jobCardProduction = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          jobCardProduction = salesList.toList();
        } else {
          jobCardProduction = salesList.toList();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _loadMonthWiseQtyAnalysis() async {
    List<MonthWiseAnalysisJobCardData> month = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String monthName = "";
    double monthlyProduction = 0.00;
    var monthlyProductionActual = const Iterable.empty();

    for (int i = 4; i <= 15; i++) {
      if (i >= 4 && i <= 12) {
        monthName = getMonthName(i);

        Map<String, DateTime> monthDates = getMonthStartEndDates(i);
        monthlyProductionActual = jobCardProduction.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.documentDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        monthName = getMonthName(i - 12);

        startDate = DateTime(currentYear, i - 12, 1);
        endDate = DateTime(currentYear, (i - 12) + 1, 0);
        monthlyProductionActual = jobCardProduction.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.documentDate);
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
      double actualAmt = 0;
      for (var target in monthlyProductionActual.toList()) {
        actualAmt = (double.tryParse(target.quantity) ?? 0);
        monthlyProduction += actualAmt;
      }
      if (monthlyProduction > 0) {
        month.add(
          MonthWiseAnalysisJobCardData(
            monthName: monthName,
            production: monthlyProduction,
          ),
        );
      }
      monthlyProduction = 0;
    }
    monthData = MonthWiseAnalysisJobCardList(monthData: month);
  }

  Future<void> _loadBranchWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseName,
  ) async {
    List<BranchWiseJobCardData> statusList = [];
    var tempList = jobCardProduction;
    String branchName = "";
    double productActual = 0.00;
    int categoryId = 0;
    var productSalesList = const Iterable.empty();

    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    productSalesList = filterProductionList(
      productSalesList.cast<ProductionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseName: warehouseName,
    );

    Set<String> processedProductCodes = {};
    for (var product in productSalesList.toList().toList()) {
      if (!processedProductCodes.contains(product.branchName)) {
        branchName = product.branchName;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.branchName == branchName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.lineTotal) ?? 0;
          productActual += salesAmt;
        }
        statusList.add(
          BranchWiseJobCardData(
            branchId: categoryId++,
            branchAmount: productActual,
            branchName: branchName,
            percentage: 0,
          ),
        );
        processedProductCodes.add(product.branchName);
      }
      productActual = 0;
      branchName = "";
    }

    double totalAmount = statusList.fold(
      0,
      (double previousValue, BranchWiseJobCardData element) =>
          previousValue + element.branchAmount,
    );

    for (BranchWiseJobCardData categoryData in statusList) {
      categoryData.percentage =
          double.tryParse(
            ((categoryData.branchAmount / totalAmount) * 100).toStringAsFixed(
              2,
            ),
          ) ??
          0;
      // categoryData.percentage = double.tryParse(
      //         (categoryData.branchAmount / 100000).toStringAsFixed(2)) ??
      //     0;
    }

    branchWiseData = BranchWiseJobCardList(branchWiseData: statusList);
  }

  Future<void> _loadGroupWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseName,
  ) async {
    List<ItemGroupWiseAnalysisJobCardData> itemGroupDataList = [];
    var tempList = jobCardProduction;
    String itemGroupName = "";
    double productActual = 0.00;
    double quantity = 0.00;
    var productSalesList = const Iterable.empty();

    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    productSalesList = filterProductionList(
      productSalesList.cast<ProductionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseName: warehouseName,
    );

    Set<String> processedProductCodes = {};
    for (var product in productSalesList.toList().toList()) {
      if (!processedProductCodes.contains(product.groupName)) {
        itemGroupName = product.groupName;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.groupName == itemGroupName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.lineTotal) ?? 0;
          double qty = double.tryParse(target.quantity) ?? 0;
          productActual += salesAmt;
          quantity += qty;
        }

        itemGroupDataList.add(
          ItemGroupWiseAnalysisJobCardData(
            itemGroupName: itemGroupName,
            lineTotal: productActual,
            quantity: quantity,
          ),
        );
        processedProductCodes.add(product.groupName);
      }
      productActual = 0;
      itemGroupName = "";
    }
    itemGroupDataList.sort((a, b) => b.lineTotal.compareTo(a.lineTotal));

    itemGroupData = ItemGroupWiseAnalysisJobCardList(
      itemGroupData: itemGroupDataList,
    );
  }

  Future<void> _loadSubGroupWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseName,
  ) async {
    List<ItemSubGroupWiseAnalysisJobCardData> itemSubGroupDataList = [];
    var tempList = jobCardProduction;
    String itemSubGroupName = "";
    double productActual = 0.00;
    double quantity = 0.00;
    var productSalesList = const Iterable.empty();

    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    productSalesList = filterProductionList(
      productSalesList.cast<ProductionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseName: warehouseName,
    );

    Set<String> processedProductCodes = {};
    for (var product in productSalesList.toList().toList()) {
      if (!processedProductCodes.contains(product.itemSubGroup)) {
        itemSubGroupName = product.itemSubGroup;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.itemSubGroup == itemSubGroupName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.lineTotal) ?? 0;
          double qty = double.tryParse(target.quantity) ?? 0;
          productActual += salesAmt;
          quantity += qty;
        }

        itemSubGroupDataList.add(
          ItemSubGroupWiseAnalysisJobCardData(
            itemSubGroupName: itemSubGroupName,
            lineTotal: productActual,
            quantity: quantity,
          ),
        );
        processedProductCodes.add(product.itemSubGroup);
      }
      productActual = 0;
      itemSubGroupName = "";
    }
    itemSubGroupDataList.sort((a, b) => b.lineTotal.compareTo(a.lineTotal));

    itemSubGroupData = ItemSubGroupWiseAnalysisJobCardList(
      itemSubGroupData: itemSubGroupDataList,
    );
  }

  Future<void> _loadWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseName,
  ) async {
    List<ItemWiseAnalysisJobCardData> itemDataList = [];
    var tempList = jobCardProduction;
    Map<String, double> productSalesMap = {};
    Map<String, double> productQuantityMap = {};
    var productSalesList = const Iterable.empty();

    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    productSalesList = filterProductionList(
      productSalesList.cast<ProductionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseName: warehouseName,
    );

    for (var product in productSalesList) {
      String itemName = product.itemDescription;
      double salesAmt = double.tryParse(product.lineTotal) ?? 0;
      double qty = double.tryParse(product.quantity) ?? 0;

      productSalesMap.update(
        itemName,
        (value) => value + salesAmt,
        ifAbsent: () => salesAmt,
      );
      productQuantityMap.update(
        itemName,
        (value) => value + qty,
        ifAbsent: () => qty,
      );
    }

    productSalesMap.forEach((itemName, totalSales) {
      double totalQuantity = productQuantityMap[itemName] ?? 0;
      itemDataList.add(
        ItemWiseAnalysisJobCardData(
          itemName: itemName,
          lineTotal: totalSales,
          quantity: totalQuantity,
        ),
      );
    });

    itemDataList.sort((a, b) => b.lineTotal.compareTo(a.lineTotal));
    itemData = ItemWiseAnalysisJobCardList(itemData: itemDataList);
  }

  Future<void> _loadWarehouseWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseName,
  ) async {
    List<WarehouseWiseAnalysisJobCardData> warehouseDataList = [];
    var tempList = jobCardProduction;
    String warehouseName = "";
    double productActual = 0.00;
    double quantity = 0.00;
    var productSalesList = const Iterable.empty();

    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    productSalesList = filterProductionList(
      productSalesList.cast<ProductionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseName: warehouseName,
    );

    Set<String> processedProductCodes = {};
    for (var product in productSalesList.toList().toList()) {
      if (!processedProductCodes.contains(product.warehouseName)) {
        warehouseName = product.warehouseName;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.warehouseName == warehouseName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.lineTotal) ?? 0;
          double qty = double.tryParse(target.quantity) ?? 0;
          productActual += salesAmt;
          quantity += qty;
        }

        warehouseDataList.add(
          WarehouseWiseAnalysisJobCardData(
            warehouseName: warehouseName,
            lineTotal: productActual,
            quantity: quantity,
          ),
        );
        processedProductCodes.add(product.warehouseName);
      }
      productActual = 0;
      warehouseName = "";
    }
    warehouseDataList.sort((a, b) => b.lineTotal.compareTo(a.lineTotal));

    warehouseData = WarehouseWiseAnalysisJobCardList(
      warehouseData: warehouseDataList,
    );
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadProductionList(userName, userLevel);
    await _loadMonthWiseQtyAnalysis();
    await _loadBranchWiseProductionOrders(0, "", "", "", "");
    await _loadGroupWiseProductionOrders(0, "", "", "", "");
    await _loadSubGroupWiseProductionOrders(0, "", "", "", "");
    await _loadWiseProductionOrders(0, "", "", "", "");
    await _loadWarehouseWiseProductionOrders(0, "", "", "", "");
    chartDataLoaded = true;
  }

  List<ProductionList> filterProductionList(
    List<ProductionList> productionList, {
    String? itemCode,
    String? itemGroup,
    String? itemSubGroup,
    String? warehouseName,
  }) {
    List<ProductionList> filteredProductionList = [];
    for (var production in productionList) {
      if ((itemCode == null ||
              itemCode.isEmpty ||
              production.itemDescription == itemCode) &&
          (itemGroup == null ||
              itemGroup.isEmpty ||
              production.groupName == itemGroup) &&
          (itemSubGroup == null ||
              itemSubGroup.isEmpty ||
              production.itemSubGroup == itemSubGroup) &&
          (warehouseName == null ||
              warehouseName.isEmpty ||
              production.warehouseName == warehouseName)) {
        filteredProductionList.add(production);
      }
    }
    return filteredProductionList;
  }

  Future<void> removeFilter() async {
    touchedMonthIndex = 0;
    touchedItemCode = "";
    touchedItemGroup = "";
    touchedItemSubGroup = "";
    touchedWarehouse = "";

    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;
    clearVariables();
    LoadDates();

    await _loadBranchWiseProductionOrders(0, "", "", "", "");
    await _loadGroupWiseProductionOrders(0, "", "", "", "");
    await _loadSubGroupWiseProductionOrders(0, "", "", "", "");
    await _loadWiseProductionOrders(0, "", "", "", "");
    await _loadWarehouseWiseProductionOrders(0, "", "", "", "");
    chartDataLoaded = true;
  }

  Future<void> loadDataWithFilter(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseName,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    await _loadBranchWiseProductionOrders(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseName,
    );
    await _loadGroupWiseProductionOrders(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseName,
    );
    await _loadSubGroupWiseProductionOrders(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseName,
    );
    await _loadWiseProductionOrders(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseName,
    );
    await _loadWarehouseWiseProductionOrders(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseName,
    );
    chartDataLoaded = true;
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;
      branchWiseData = BranchWiseJobCardList(branchWiseData: []);
      itemGroupData = ItemGroupWiseAnalysisJobCardList(itemGroupData: []);
      itemSubGroupData = ItemSubGroupWiseAnalysisJobCardList(
        itemSubGroupData: [],
      );
      itemData = ItemWiseAnalysisJobCardList(itemData: []);
      warehouseData = WarehouseWiseAnalysisJobCardList(warehouseData: []);
      touchedMonthIndex = 0;
      touchedItemCode = "";
      touchedItemGroup = "";
      touchedItemSubGroup = "";
      touchedWarehouse = "";
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoaded = false;
      branchWiseData = BranchWiseJobCardList(branchWiseData: []);
      itemGroupData = ItemGroupWiseAnalysisJobCardList(itemGroupData: []);
      itemSubGroupData = ItemSubGroupWiseAnalysisJobCardList(
        itemSubGroupData: [],
      );
      itemData = ItemWiseAnalysisJobCardList(itemData: []);
      warehouseData = WarehouseWiseAnalysisJobCardList(warehouseData: []);
    });
  }

  Future<void> generateMonthlyJobcardExcel(
    MonthWiseAnalysisJobCardList monthWiseAnalysisJobCardList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'MonthlyJobcard',
      headers: ['Month', 'Quantity'],
      rows: monthWiseAnalysisJobCardList.monthData
          .map((monthlyData) => [monthlyData.monthName, monthlyData.production])
          .toList(),
      fileName: 'monthly_jobcard_report.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Production - Monthly Jobcard',
    );
  }

  Future<void> generateMonthlyJobcardPDF(
    MonthWiseAnalysisJobCardList monthWiseAnalysisJobCardList,
  ) async {
    await reportService.generatePDF(
      title: 'MonthlyJobcard',
      headers: ['Month', 'Quantity'],
      rows: monthWiseAnalysisJobCardList.monthData
          .map((monthlyData) => [monthlyData.monthName, monthlyData.production])
          .toList(),
      fileName: 'monthly_jobcard_report.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateBranchJobcardExcel(
    BranchWiseJobCardList branchWiseJobCardList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'BranchWiseJobcard',
      headers: ['Branch Name', 'Line Total', 'Percentage'],
      rows: branchWiseJobCardList.branchWiseData
          .map(
            (itemData) => [
              itemData.branchName,
              itemData.branchAmount.toStringAsFixed(2),
              itemData.percentage.toStringAsFixed(2),
            ],
          )
          .toList(),
      fileName: 'monthly_jobcard_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Branch Wise Jobcard',
    );
  }

  Future<void> generateBranchJobcardPDF(
    BranchWiseJobCardList branchWiseJobCardList,
  ) async {
    await reportService.generatePDF(
      title: 'BranchWiseJobcard',
      headers: ['Branch Name', 'Line Total', 'Percentage'],
      rows: branchWiseJobCardList.branchWiseData
          .map(
            (itemData) => [
              itemData.branchName,
              itemData.branchAmount.toStringAsFixed(2),
              itemData.percentage.toStringAsFixed(2),
            ],
          )
          .toList(),
      fileName: 'monthly_jobcard_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateItemGroupJobcardExcel(
    ItemGroupWiseAnalysisJobCardList itemGroupWiseAnalysisJobCardList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ItemGroupWiseJobcard',
      headers: ['Group Name', 'Line Total', 'Quantity'],
      rows: itemGroupWiseAnalysisJobCardList.itemGroupData
          .map(
            (itemData) => [
              itemData.itemGroupName,
              itemData.lineTotal.toStringAsFixed(2),
              itemData.quantity.toStringAsFixed(2),
            ],
          )
          .toList(),
      fileName: 'itemgroup_jobcard_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Item Group Wise Jobcard',
    );
  }

  Future<void> generateItemGroupJobcardPDF(
    ItemGroupWiseAnalysisJobCardList itemGroupWiseAnalysisJobCardList,
  ) async {
    await reportService.generatePDF(
      title: 'ItemGroupWiseJobcard',
      headers: ['Group Name', 'Line Total', 'Quantity'],
      rows: itemGroupWiseAnalysisJobCardList.itemGroupData
          .map(
            (itemData) => [
              itemData.itemGroupName,
              itemData.lineTotal.toStringAsFixed(2),
              itemData.quantity.toStringAsFixed(2),
            ],
          )
          .toList(),
      fileName: 'itemgroup_jobcard_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateItemSubGroupJobcardExcel(
    ItemSubGroupWiseAnalysisJobCardList itemSubGroupWiseAnalysisJobCardList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ItemSubGroupWiseJobcard',
      headers: ['Group Name', 'Line Total', 'Quantity'],
      rows: itemSubGroupWiseAnalysisJobCardList.itemSubGroupData
          .map(
            (itemData) => [
              itemData.itemSubGroupName,
              itemData.lineTotal.toStringAsFixed(2),
              itemData.quantity.toStringAsFixed(2),
            ],
          )
          .toList(),
      fileName: 'itemsubgroup_jobcard_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Item Sub Group Wise Jobcard',
    );
  }

  Future<void> generateItemSubGroupJobcardPDF(
    ItemSubGroupWiseAnalysisJobCardList itemSubGroupWiseAnalysisJobCardList,
  ) async {
    await reportService.generatePDF(
      title: 'ItemSubGroupWiseJobcard',
      headers: ['Group Name', 'Line Total', 'Quantity'],
      rows: itemSubGroupWiseAnalysisJobCardList.itemSubGroupData
          .map(
            (itemData) => [
              itemData.itemSubGroupName,
              itemData.lineTotal.toStringAsFixed(2),
              itemData.quantity.toStringAsFixed(2),
            ],
          )
          .toList(),
      fileName: 'itemsubgroup_jobcard_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateItemWiseJobcardExcel(
    ItemWiseAnalysisJobCardList itemDescriptionWiseAnalysisJobCardList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ItemWiseJobcard',
      headers: ['Item Name', 'Line Total', 'Quantity'],
      rows: itemDescriptionWiseAnalysisJobCardList.itemData
          .map(
            (itemData) => [
              itemData.itemName,
              itemData.lineTotal.toStringAsFixed(2),
              itemData.quantity.toStringAsFixed(2),
            ],
          )
          .toList(),
      fileName: 'item_jobcard_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Item Wise Jobcard',
    );
  }

  Future<void> generateItemWiseJobcardPDF(
    ItemWiseAnalysisJobCardList itemDescriptionWiseAnalysisJobCardList,
  ) async {
    await reportService.generatePDF(
      title: 'ItemWiseJobcard',
      headers: ['Item Name', 'Line Total', 'Quantity'],
      rows: itemDescriptionWiseAnalysisJobCardList.itemData
          .map(
            (itemData) => [
              itemData.itemName,
              itemData.lineTotal.toStringAsFixed(2),
              itemData.quantity.toStringAsFixed(2),
            ],
          )
          .toList(),
      fileName: 'item_jobcard_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateWarehouseJobcardExcel(
    WarehouseWiseAnalysisJobCardList warehouseWiseAnalysisJobCardList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'WarehouseWiseJobcard',
      headers: ['Warehouse', 'Line Total', 'Quantity'],
      rows: warehouseWiseAnalysisJobCardList.warehouseData
          .map(
            (itemData) => [
              itemData.warehouseName,
              itemData.lineTotal.toStringAsFixed(2),
              itemData.quantity.toStringAsFixed(2),
            ],
          )
          .toList(),
      fileName: 'warehouse_jobcard_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Warehouse Wise Jobcard',
    );
  }

  Future<void> generateWarehouseJobcardPDF(
    WarehouseWiseAnalysisJobCardList warehouseWiseAnalysisJobCardList,
  ) async {
    await reportService.generatePDF(
      title: 'WarehouseWiseJobcard',
      headers: ['Warehouse', 'Line Total', 'Quantity'],
      rows: warehouseWiseAnalysisJobCardList.warehouseData
          .map(
            (itemData) => [
              itemData.warehouseName,
              itemData.lineTotal.toStringAsFixed(2),
              itemData.quantity.toStringAsFixed(2),
            ],
          )
          .toList(),
      fileName: 'warehouse_jobcard_report.xlsx',
      amountColumns: [2, 3],
    );
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _monthWiseHorizontalController = ScrollController();
  final ScrollController _itemWiseHorizontalController = ScrollController();
  final ScrollController _warehouseWiseHorizontalController =
      ScrollController();
  final ScrollController _itemGroupWiseHorizontalController =
      ScrollController();
  final ScrollController _itemSubGroupWiseHorizontalController =
      ScrollController();
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
    _monthWiseHorizontalController.dispose();
    _itemWiseHorizontalController.dispose();
    _itemGroupWiseHorizontalController.dispose();
    _itemSubGroupWiseHorizontalController.dispose();
    _warehouseWiseHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Month Wise Qty Analysis',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateMonthlyJobcardExcel(monthData);
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateMonthlyJobcardPDF(monthData);
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _monthWiseQtyAnalysis(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Branch Wise Line Total Analysis',
                    trailing: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  for (final categoryData
                                      in branchWiseData.branchWiseData)
                                    Column(
                                      children: [
                                        Container(
                                          height: 8,
                                          width: 16,
                                          color: getCategoryColor(
                                            categoryData.branchId,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final categoryData
                                in branchWiseData.branchWiseData)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  categoryData.branchName,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          setState(() {
                            generateBranchJobcardExcel(branchWiseData);
                          });
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          setState(() {
                            generateBranchJobcardPDF(branchWiseData);
                          });
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],

                    child: SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          borderData: FlBorderData(show: false),
                          sections: showingSectionsBranchWise(),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Item Wise Analysis',
                    spacing: 20,
                    trailing: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFFFF9F47),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Line Total",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFF97D7F3),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Quantity",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateItemWiseJobcardExcel(itemData);
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateItemWiseJobcardPDF(itemData);
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _itemWiseAnalysis(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Item Group Wise Analysis',
                    spacing: 20,
                    trailing: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFFFF9F47),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Line Total",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFF97D7F3),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Quantity",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateItemGroupJobcardExcel(itemGroupData);
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateItemGroupJobcardPDF(itemGroupData);
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _itemGroupWiseAnalysis(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Item Sub Group Wise Analysis',
                    spacing: 20,
                    trailing: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFFFF9F47),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Line Total",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFF97D7F3),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Quantity",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateItemSubGroupJobcardExcel(itemSubGroupData);
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateItemSubGroupJobcardExcel(itemSubGroupData);
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _itemSubGroupWiseAnalysis(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Warehouse Wise Analysis',
                    spacing: 20,
                    trailing: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFFFF9F47),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Line Total",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFF97D7F3),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Quantity",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateWarehouseJobcardExcel(warehouseData);
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateWarehouseJobcardPDF(warehouseData);
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _warehouseWiseAnalysis(),
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

  Widget _monthWiseQtyAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthData.monthData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? monthData.monthData
              .map(
                (data) => data.production > data.production
                    ? data.production
                    : data.production,
              )
              .reduce((a, b) => a > b ? a : b) // Find the max value
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _monthWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxValue),
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
                  sideTitles: _bottomTitlesMonthWiseQtyAnalysis,
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
              barGroups: _monthWiseQtyAnalysisChartData(monthData.monthData),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      touchedMonth = monthData
                          .monthData[barTouchResponse.spot!.spot.x.toInt()]
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
                          touchedItemCode,
                          touchedItemGroup,
                          touchedItemSubGroup,
                          touchedWarehouse,
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
                      '${monthData.monthData[grpIndex].monthName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: formatAmount(
                            monthData.monthData[grpIndex].production,
                          ),
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
    double chartWidth = 0.0;
    int len = itemData.itemData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? itemData.itemData
              .map(
                (data) => data.lineTotal > data.lineTotal
                    ? data.lineTotal
                    : data.lineTotal,
              )
              .reduce((a, b) => a > b ? a : b) // Find the max value
        : 0;
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
              maxY: getMaxValue(maxValue),
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
                  sideTitles: _bottomTitlesItemDescriptionWiseAnalysis,
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
              barGroups: _itemWiseAnalysisChartData(itemData.itemData),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedItemCode = touchedItemCode == ""
                            ? itemData
                                  .itemData[barTouchResponse.spot!.spot.x
                                      .toInt()]
                                  .itemName
                            : "";
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showDrillDownChart = true;
                        loadDataWithFilter(
                          touchedMonthIndex,
                          touchedItemCode,
                          touchedItemGroup,
                          touchedItemSubGroup,
                          touchedWarehouse,
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
                      '${itemData.itemData[grpIndex].itemName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Line Total : ${formatAmount(itemData.itemData[grpIndex].lineTotal)}\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Quantity : ${formatAmount(itemData.itemData[grpIndex].quantity)}",
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

  Widget _itemGroupWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemGroupData.itemGroupData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? itemGroupData.itemGroupData
              .map(
                (data) => data.lineTotal > data.lineTotal
                    ? data.lineTotal
                    : data.lineTotal,
              )
              .reduce((a, b) => a > b ? a : b) // Find the max value
        : 0;
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
              maxY: getMaxValue(maxValue),
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
                  sideTitles: _bottomTitlesItemGroupWiseAnalysis,
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
                itemGroupData.itemGroupData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedItemGroup = touchedItemGroup == ""
                            ? itemGroupData
                                  .itemGroupData[barTouchResponse.spot!.spot.x
                                      .toInt()]
                                  .itemGroupName
                            : "";
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showDrillDownChart = true;
                        loadDataWithFilter(
                          touchedMonthIndex,
                          touchedItemCode,
                          touchedItemGroup,
                          touchedItemSubGroup,
                          touchedWarehouse,
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
                      '${itemGroupData.itemGroupData[grpIndex].itemGroupName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Line Total : ${formatAmount(itemGroupData.itemGroupData[grpIndex].lineTotal)}\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Quantity : ${formatAmount(itemGroupData.itemGroupData[grpIndex].quantity)}",
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

  Widget _itemSubGroupWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemSubGroupData.itemSubGroupData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? itemSubGroupData.itemSubGroupData
              .map(
                (data) => data.lineTotal > data.lineTotal
                    ? data.lineTotal
                    : data.lineTotal,
              )
              .reduce((a, b) => a > b ? a : b) // Find the max value
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _itemSubGroupWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxValue),
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
                  sideTitles: _bottomTitlesItemSubGroupWiseAnalysis,
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
              barGroups: _itemSubGroupWiseAnalysisChartData(
                itemSubGroupData.itemSubGroupData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedItemSubGroup = touchedItemSubGroup == ""
                            ? itemSubGroupData
                                  .itemSubGroupData[barTouchResponse
                                      .spot!
                                      .spot
                                      .x
                                      .toInt()]
                                  .itemSubGroupName
                            : "";
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showDrillDownChart = true;
                        loadDataWithFilter(
                          touchedMonthIndex,
                          touchedItemCode,
                          touchedItemGroup,
                          touchedItemSubGroup,
                          touchedWarehouse,
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
                      '${itemSubGroupData.itemSubGroupData[grpIndex].itemSubGroupName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Line Total : ${formatAmount(itemSubGroupData.itemSubGroupData[grpIndex].lineTotal)}\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Quantity : ${formatAmount(itemSubGroupData.itemSubGroupData[grpIndex].quantity)}",
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

  Widget _warehouseWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = warehouseData.warehouseData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? warehouseData.warehouseData
              .map(
                (data) => data.lineTotal > data.lineTotal
                    ? data.lineTotal
                    : data.lineTotal,
              )
              .reduce((a, b) => a > b ? a : b) // Find the max value
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _warehouseWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxValue),
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
                  sideTitles: _bottomTitlesWarehouseWiseAnalysis,
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
              barGroups: _warehouseWiseAnalysisChartData(
                warehouseData.warehouseData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedWarehouse = touchedWarehouse == ""
                            ? warehouseData
                                  .warehouseData[barTouchResponse.spot!.spot.x
                                      .toInt()]
                                  .warehouseName
                            : "";
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showDrillDownChart = true;
                        loadDataWithFilter(
                          touchedMonthIndex,
                          touchedItemCode,
                          touchedItemGroup,
                          touchedItemSubGroup,
                          touchedWarehouse,
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
                      '${warehouseData.warehouseData[grpIndex].warehouseName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Line Total : ${formatAmount(warehouseData.warehouseData[grpIndex].lineTotal)}\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Quantity : ${formatAmount(warehouseData.warehouseData[grpIndex].quantity)}",
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
