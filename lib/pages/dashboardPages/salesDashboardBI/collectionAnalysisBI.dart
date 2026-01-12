// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, avoid_web_libraries_in_flutter, strict_top_level_inference
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
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import 'package:optima/login_screen.dart';
import '../../../classes/dashBoard.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:optima/pages/dashboardPages/platform_excel_helper.dart';
import 'package:optima/pages/dashboardPages/platform_pdf_helper.dart';

bool touchedLastMonthGoals = false;
bool touchedThisMonthGoals = false;
bool touchedYTDGoals = false;
bool YtdColBarChartData = false;
YTDCollectionList ytdCollectionList = YTDCollectionList(ytdColData: []);
MonthlyColectionList monthlyCollectionList = MonthlyColectionList(
  monthlyData: [],
);
CustomerWiseCollectionList customerWiseCollectionList =
    CustomerWiseCollectionList(customerData: []);
TsmwiseCollectionList tsmwiseCollectionList = TsmwiseCollectionList(
  tsmwiseData: [],
);
AsmwiseCollectionList asmwiseCollectionList = AsmwiseCollectionList(
  asmwiseData: [],
);
RsmwiseCollectionList rsmwiseCollectionList = RsmwiseCollectionList(
  rsmwiseData: [],
);
ReceivablesCategoryList receivablesCategoryList = ReceivablesCategoryList(
  categoryData: [],
);
ReceivablesAgingList receivablesAgingList = ReceivablesAgingList(agingData: []);

int touchedMonthIndex = 0;
String touchedRegionalManager = "";
String touchedSalesManager = "";
String touchedSalesRep = "";
String touchedMonth = "";
String touchedState = "";
String touchedCustomer = "";
String touchedProductGroup = "";
String touchedProduct = "";
String touchedAgingCategory = "";
String UserLevel = "0";
double maxMonthY = 0.0;
double barChartWidthProduct = 0.0;
double maxItemMonthY = 0.0;
double selectedChart = 0;
List<Map<String, dynamic>> userList = [];
List<Map<String, dynamic>> collectionsTargetList = [];
late Future<void> loadDataFuture;
List<Users> usersList = [];
List<Users> childUsers = [];
List<Users> usersListForFilter = [];
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
List<Map<String, dynamic>> collectionList = [];
List<CollectionList> collection = [];
List<DebtorsAgingList> target = [];
List<Map<String, dynamic>> collectionsList = [];
bool noUserList = false;
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

double Q1Collection = 0;
double Q1Target = 0;
double Q1Diff = 0;
int Q1Percentage = 0;
String Q1CollectionStr = "";
String Q1TargetStr = "";
String Q1DiffStr = "";
String Q1PercentageStr = "";
double Q2Collection = 0;
double Q2Target = 0;
double Q2Diff = 0;
int Q2Percentage = 0;
String Q2CollectionStr = "";
String Q2TargetStr = "";
String Q2DiffStr = "";
String Q2PercentageStr = "";
double Q3Collection = 0;
double Q3Target = 0;
double Q3Diff = 0;
int Q3Percentage = 0;
String Q3CollectionStr = "";
String Q3TargetStr = "";
String Q3DiffStr = "";
String Q3PercentageStr = "";
double Q4Collection = 0;
double Q4Target = 0;
double Q4Diff = 0;
int Q4Percentage = 0;
String Q4CollectionStr = "";
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

final List<String> categories = ['RSM', 'ASM', 'TSM', 'Date'];

List<List<String>> filterOptions = [listOfRSM, listOfASM, listOfTSM, []];

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
List<String> selectedSalesData = [];

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

class CollectionListCollectionsAnalysisBIProvider with ChangeNotifier {
  List<CollectionList> _collectionList = [];
  List<CollectionList> get collectionList => _collectionList;
  void updateCollectionList(List<CollectionList> newCollectionList) {
    _collectionList = newCollectionList;
    notifyListeners();
  }
}

class TargetListCollectionsAnalysisBIProvider with ChangeNotifier {
  List<DebtorsAgingList> _targetList = [];
  List<DebtorsAgingList> get targetList => _targetList;
  void updateTargetList(List<DebtorsAgingList> newTargetList) {
    _targetList = newTargetList;
    notifyListeners();
  }
}

class CollectionAnalysisPage extends StatefulWidget {
  const CollectionAnalysisPage({super.key});

  @override
  State<CollectionAnalysisPage> createState() => _CollectionAnalysisPageState();
}

class _CollectionAnalysisPageState extends State<CollectionAnalysisPage> {
  ScrollController collectionAnalysisController = ScrollController();
  int touchedIndex = -1;
  bool showDrillDownChart = false;
  bool showProductSaleChart = false;
  bool showLastMonthBarChart = false;
  bool lastMonthChartFunc = false;
  bool lastThreeMonthChartFunc = false;
  bool touchedYearGraph = false;
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
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

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

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

  SideTitles get _bottomTitlesMonthWiseCollection =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitles);

  SideTitles get _bottomTitlesCustomer => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      CustomerWiseCollectionData customerWiseData = customerWiseCollectionList
          .customerData
          .elementAt(value.toInt());
      text = customerWiseData.customerName;
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

  Widget getBottomTitles(double val, TitleMeta meta) {
    String text = '';
    MonthlyCollectionData monthlyCollectionData = monthlyCollectionList
        .monthlyData
        .elementAt(val.toInt());
    text = monthlyCollectionData.monthName;
    return Text(text.length > 3 ? text.substring(0, 3) : text);
  }

  SideTitles get _bottomTitlesReceivableAging => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ReceivablesAgingData> mData = receivablesAgingList.agingData;
      text = mData.elementAt(value.toInt()).agingGroup;
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

  SideTitles get _bottomTitlesTsm =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitlesTsm);

  SideTitles get _bottomTitlesAsm =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitlesAsm);

  Widget getBottomTitlesAsm(double val, TitleMeta meta) {
    String text = '';
    AsmwiseCollectionData asmwiseData = asmwiseCollectionList.asmwiseData
        .elementAt(val.toInt());
    text = asmwiseData.asmName;
    return Text(text.length > 5 ? text.substring(0, 5) : text);
  }

  Widget getBottomTitlesTsm(double val, TitleMeta meta) {
    String text = '';
    TsmwiseCollectionData tsmwiseData = tsmwiseCollectionList.tsmwiseData
        .elementAt(val.toInt());
    text = tsmwiseData.tsmName;
    return Text(text.length > 5 ? text.substring(0, 5) : text);
  }

  SideTitles get _bottomTitlesRsm =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitlesRsm);

  Widget getBottomTitlesRsm(double val, TitleMeta meta) {
    String text = '';
    RsmwiseCollectionData rsmwiseData = rsmwiseCollectionList.rsmwiseData
        .elementAt(val.toInt());
    text = rsmwiseData.rsmName;
    return Text(text.length > 5 ? text.substring(0, 5) : text);
  }

  List<BarChartGroupData> _receivableAgingChartData(
    List<ReceivablesAgingData> agingData,
  ) {
    return agingData
        .map(
          (aging) => BarChartGroupData(
            x: agingData.indexOf(aging),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: aging.agingGroupTotal,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _monthWiseCollectionAnalysisChartData(
    List<MonthlyCollectionData> monthlyData,
  ) {
    return monthlyData
        .map(
          (collection) => BarChartGroupData(
            x: monthlyData.indexOf(collection),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: collection.collectionTarget,
                  show: true,
                  color: const Color(0xFF6CCC3F),
                ),
                color: const Color(0xFFF49136),
                borderRadius: BorderRadius.zero,
                toY: collection.collectionAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _customerAnalysisChartData(
    List<CustomerWiseCollectionData> customerData,
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
                  color: const Color(0xFF6CCC3F),
                ),
                color: const Color(0xFFF49136),
                borderRadius: BorderRadius.zero,
                toY: customer.collectionAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _salesManagerAnalysisChartData(
    List<AsmwiseCollectionData> asmwiseData,
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
                  color: const Color(0xFF97D7F3),
                ),
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: asm.collectionAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _salesPersonAnalysisChart(
    List<TsmwiseCollectionData> tsmwiseData,
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
                  color: const Color(0xFF97D7F3),
                ),
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: tsm.collectionAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _regionalManagerAnalysisChart(
    List<RsmwiseCollectionData> rsmwiseData,
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
                  color: const Color(0xFF97D7F3),
                ),
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: rsm.collectionAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<PieChartSectionData> _receivablesCategoryChart() {
    final List<PieChartSectionData> sections = [];
    for (final categoryData in receivablesCategoryList.categoryData) {
      final fontSize = touchedIndex >= 1 ? 12.0 : 11.0;
      final radius = touchedIndex >= 1 ? 80.0 : 75.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      // Create PieChartSectionData based on categoryData
      final sectionData = PieChartSectionData(
        color: getCategoryColor(
          categoryData.categoryId,
        ), // Define a method to get color based on categoryId
        value: categoryData.categoryPercentage,
        title: '${categoryData.categoryPercentage.toStringAsFixed(2)} %',
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

  double getAgingMaxValue(ReceivablesAgingList receivablesAgingList) {
    double maxValue = 0.0;
    for (var monthlyData in receivablesAgingList.agingData) {
      maxValue = maxValue > monthlyData.agingGroupTotal
          ? maxValue
          : monthlyData.agingGroupTotal;
    }
    return ((maxValue ~/ 200000) + 1) * 200000;
  }

  double getMaxValue(MonthlyColectionList monthlyCollectionsList) {
    double maxValue = 0.0;
    for (var monthlyData in monthlyCollectionsList.monthlyData) {
      maxValue = maxValue > monthlyData.collectionAmount
          ? maxValue
          : monthlyData.collectionAmount;
      maxValue = maxValue > monthlyData.collectionTarget
          ? maxValue
          : monthlyData.collectionTarget;
    }
    return ((maxValue ~/ 1000000) + 1) * 1000000;
  }

  double getCustomerMaxValue(CustomerWiseCollectionList customerAnalysisData) {
    double maxValue = 0.0;
    for (var soData in customerAnalysisData.customerData) {
      maxValue = maxValue > soData.collectionAmount
          ? maxValue
          : soData.collectionAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    return ((maxValue ~/ 100000) + 1) * 100000;
  }

  double getAsmMaxValue(AsmwiseCollectionList salesManagerData) {
    double maxValue = 0.0;
    for (var soData in salesManagerData.asmwiseData) {
      maxValue = maxValue > soData.collectionAmount
          ? maxValue
          : soData.collectionAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    return ((maxValue ~/ 500000) + 1) * 500000;
  }

  double getTsmMaxValue(TsmwiseCollectionList salesPersonData) {
    double maxValue = 0.0;
    for (var soData in salesPersonData.tsmwiseData) {
      maxValue = maxValue > soData.collectionAmount
          ? maxValue
          : soData.collectionAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    return ((maxValue ~/ 500000) + 1) * 500000;
  }

  double getRsmMaxValue(RsmwiseCollectionList rsmManagerData) {
    double maxValue = 0.0;
    for (var soData in rsmManagerData.rsmwiseData) {
      maxValue = maxValue > soData.collectionAmount
          ? maxValue
          : soData.targetAmount;
      maxValue = maxValue > soData.targetAmount
          ? maxValue
          : soData.targetAmount;
    }
    return ((maxValue ~/ 1000000) + 1) * 1000000;
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

  Future<void> _loadCollection(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<CollectionList> collectionList = [];
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
        const apiUrl = '${ApiHelper.baseUrl}CRMCollectionAnalysisList';
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
            List<CollectionList> newCollectionList =
                (responseJson['responseData'] as List)
                    .map((item) => CollectionList.fromJson(item))
                    .toList();

            collectionList.addAll(newCollectionList);
            fetchedCount = newCollectionList.length;
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
            .read<CollectionListCollectionsAnalysisBIProvider>()
            .updateCollectionList(collectionList);

        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);

        if (int.parse(UserLevel) == 5) {
          collection = collectionList.toList();
        } else if (int.parse(UserLevel) == 4) {
          collection = collectionList
              .where((element) => element.regionalManager == UserName)
              .toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          collection = collectionList.where((element) {
            return menuNames.contains(element.salesManager);
          }).toList();
        } else {
          collection = collectionList
              .where((element) => element.salesRep == UserName)
              .toList();
        }
      });

      List<CollectionList> filteredList = [];

      List<String> trueRSMOptions = (allCategoriesState['RSM'] ?? {}).entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      List<String> trueASMOptions = (allCategoriesState['ASM'] ?? {}).entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      List<String> trueTSMOptions = (allCategoriesState['TSM'] ?? {}).entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (trueRSMOptions.isNotEmpty) {
        filteredList = collection
            .where((person) => trueRSMOptions.contains(person.regionalManager))
            .toList();

        collection = filteredList;
      }

      if (trueASMOptions.isNotEmpty) {
        filteredList = collection
            .where((person) => trueASMOptions.contains(person.salesManager))
            .toList();
        collection = filteredList;
      }

      if (trueTSMOptions.isNotEmpty) {
        filteredList = collection
            .where((person) => trueTSMOptions.contains(person.salesRep))
            .toList();
        collection = filteredList;
      }

      double sum = 0;
      var currentMonthCollection = collection.where((target) {
        DateTime postingDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.postingDate);
        return postingDate.isAtLeast(currentMonthFromDate!) &&
            postingDate.isAtMost(currentDate!);
      });
      for (var target in currentMonthCollection.toList()) {
        sum += double.tryParse(target.total) ?? 0;
      }
      Collections = sum;
      CollectionsStr = "${(sum / 100000).toStringAsFixed(2)} L";
      CollectionGoal = Collections + CollectionGoal;
      CollectionPercentage =
          double.tryParse(
            ((Collections /
                        (CollectionGoal == 0 ? Collections : CollectionGoal)) *
                    100)
                .toStringAsFixed(2),
          )?.ceil() ??
          0;

      CollectionPercentageStr = "${CollectionPercentage.toString()} %";
      CollectionsGoalStr = "${(CollectionGoal / 100000).toStringAsFixed(2)} L";
      if (CollectionPercentage > 100) {
        CollectionPercentage = 100;
      }

      var lastMonthCollection = collection.where((target) {
        DateTime postingDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.postingDate);
        return postingDate.isAtLeast(lastMonthFromDate!) &&
            postingDate.isAtMost(lastMonthToDate!);
      });
      sum = 0;
      for (var target in lastMonthCollection.toList()) {
        sum += double.tryParse(target.total) ?? 0;
      }
      LastMonthCollections = sum;
      LastMonthCollectionsStr =
          "${(LastMonthCollections / 100000).toStringAsFixed(2)} L";
      LastMonthTarget = LastMonthTarget + sum;
      LastMonthPercentage =
          double.tryParse(
            ((LastMonthCollections /
                        (LastMonthTarget == 0
                            ? LastMonthCollections
                            : LastMonthTarget)) *
                    100)
                .toStringAsFixed(2),
          )?.ceil() ??
          0;

      LastMonthPercentageStr = "${LastMonthPercentage.toString()} %";
      if (LastMonthPercentage > 100) {
        LastMonthPercentage = 100;
      }
      LastMonthTargetStr = "${(LastMonthTarget / 100000).toStringAsFixed(2)} L";

      var curQtrCollections = collection.where((target) {
        DateTime postingDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.postingDate);
        return postingDate.isAtLeast(currentQuarterFromDate!) &&
            postingDate.isAtMost(currentQuarterToDate!);
      });
      sum = 0;
      for (var target in curQtrCollections.toList()) {
        sum += double.tryParse(target.total) ?? 0;
      }
      CurrentQtrCollections = sum;
      CurrentQtrCollectionsStr =
          "${(CurrentQtrCollections / 100000).toStringAsFixed(2)} L";
      CurrentQtrTarget = CurrentQtrTarget + sum;
      if (CurrentQtrCollections == 0) {
        CurrentQtrPercentage = 0;
      } else {
        CurrentQtrPercentage =
            double.tryParse(
              ((CurrentQtrCollections /
                          (CurrentQtrTarget == 0
                              ? CurrentQtrCollections
                              : CurrentQtrTarget)) *
                      100)
                  .toStringAsFixed(2),
            )?.ceil() ??
            0;
      }

      CurrentQtrPercentageStr = "${CurrentQtrPercentage.toString()} %";
      if (CurrentQtrPercentage > 100) {
        CurrentQtrPercentage = 100;
      }
      CurrentQtrTargetStr =
          "${(CurrentQtrTarget / 100000).toStringAsFixed(2)} L";

      var ytdCollections = collection.where((target) {
        DateTime postingDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.postingDate);
        return postingDate.isAtLeast(fiscalYearStartDate!) &&
            postingDate.isAtMost(currentDate!);
      });
      sum = 0;
      for (var target in ytdCollections.toList()) {
        sum += double.tryParse(target.total) ?? 0;
      }
      YtdCollections = sum;
      YtdCollectionsStr = "${(YtdCollections / 100000).toStringAsFixed(2)} L";
      YtdTarget = YtdTarget + sum;
      if (YtdCollections == 0) {
        YtdPercentage = 0;
      } else {
        YtdPercentage =
            double.tryParse(
              ((YtdCollections /
                          (YtdTarget == 0 ? YtdCollections : YtdTarget)) *
                      100)
                  .toStringAsFixed(2),
            )?.ceil() ??
            0;
      }

      YtdPercentageStr = "${YtdPercentage.toString()} %";
      if (YtdPercentage > 100) {
        YtdPercentage = 100;
      }
      YtdTargetStr = "${(YtdTarget / 100000).toStringAsFixed(2)} L";
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadCollectionTarget(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<DebtorsAgingList> targetList = [];
    try {
      do {
        var body = {
          "FromDate": formatDate(prevFiscalYearStartDate!),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}Bicxo_DebtorsAgingList';
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
            List<DebtorsAgingList> newTargetList =
                (responseJson['responseData'] as List)
                    .map((item) => DebtorsAgingList.fromJson(item))
                    .toList();
            targetList.addAll(newTargetList);
            fetchedCount = newTargetList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        context
            .read<TargetListCollectionsAnalysisBIProvider>()
            .updateTargetList(targetList);
        if (int.parse(UserLevel) == 5) {
          target = targetList.toList();
        } else if (int.parse(UserLevel) == 4) {
          target = targetList
              .where((element) => element.regionalManager == UserName)
              .toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          target = targetList.where((element) {
            return menuNames.contains(element.salesManager);
          }).toList();
        } else {
          target = targetList
              .where((element) => element.salesRep == UserName)
              .toList();
        }
      });
      double sum = 0;
      var currentMonthTarget = target.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
        return dueon.isAtMost(currentMonthToDate!);
      });
      for (var target in currentMonthTarget.toList()) {
        double balance = double.tryParse(target.balance) ?? 0;
        // sum += balance;
        if (double.tryParse(target.future)! <= 0) {
          sum += balance;
        }
      }
      CollectionGoal = sum;

      var lastMonthTarget = target.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
        return dueon.isAtMost(lastMonthToDate!);
      });
      sum = 0;
      for (var target in lastMonthTarget.toList()) {
        double balance = double.tryParse(target.balance) ?? 0;
        // sum += balance;
        if (double.tryParse(target.future)! <= 0) {
          sum += balance;
        }
      }
      LastMonthTarget = sum;

      var curQtrTarget = target.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
        return dueon.isAtMost(currentQuarterToDate!);
      });
      sum = 0;
      for (var target in curQtrTarget.toList()) {
        double balance = double.tryParse(target.balance) ?? 0;
        // sum += balance;
        if (double.tryParse(target.future)! <= 0) {
          sum += balance;
        }
      }
      CurrentQtrTarget = sum;

      var ytdTarget = target.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
        return dueon.isAtMost(currentDate!);
      });
      sum = 0;
      for (var target in ytdTarget.toList()) {
        double balance = double.tryParse(target.balance) ?? 0;
        // sum += balance;
        if (double.tryParse(target.future)! <= 0) {
          sum += balance;
        }
      }
      YtdTarget = sum;
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
          var curQtrTarget = target.where((target) {
            DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
            return dueon.isAtMost(q1ToDate!);
          });
          sum = 0;
          for (var target in curQtrTarget.toList()) {
            if (double.tryParse(target.future)! <= 0) {
              sum += double.tryParse(target.balance) ?? 0;
            }
          }
          Q1Target = sum;
          var curQtrSales = collection.where((target) {
            DateTime postingDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.postingDate);
            return postingDate.isAtLeast(q1FromDate!) &&
                postingDate.isAtMost(q1ToDate!);
          });
          sum = 0;
          for (var target in curQtrSales.toList()) {
            sum += double.tryParse(target.total) ?? 0;
          }
          Q1Collection = sum;
          Q1CollectionStr = "${(Q1Collection / 100000).toStringAsFixed(2)} L";
          Q1Target += Q1Collection;
          Q1TargetStr = "${(Q1Target / 100000).toStringAsFixed(2)} L";
          if (Q1Collection == 0) {
            Q1Percentage = 0;
          } else {
            Q1Percentage =
                double.tryParse(
                  ((Q1Collection / (Q1Target == 0 ? Q1Collection : Q1Target)) *
                          100)
                      .toStringAsFixed(2),
                )?.ceil() ??
                0;
          }

          Q1PercentageStr = "${Q1Percentage.toString()}%";
          if (Q1Percentage > 100) {
            Q1Percentage = 100;
          }
          Q1Average = (Q1Collection / MonthDiffs);
          Q1AverageStr = "${(Q1Average / 100000).toStringAsFixed(2)} L";
          Q1DiffStr =
              "${((Q1Target - Q1Collection > 0 ? Q1Target - Q1Collection : 0) / 100000).toStringAsFixed(2)} L";
          break;
        case 2:
          sum = 0;
          MonthDiffs = monthDifference(q2FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q2FromDate!, currentDate!);
          var curQtrTarget = target.where((target) {
            DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
            return dueon.isAtMost(q2ToDate!);
          });
          sum = 0;
          for (var target in curQtrTarget.toList()) {
            if (double.tryParse(target.future)! <= 0) {
              sum += double.tryParse(target.balance) ?? 0;
            }
          }
          Q2Target = sum;
          var curQtrSales = collection.where((target) {
            DateTime postingDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.postingDate);
            return postingDate.isAtLeast(q2FromDate!) &&
                postingDate.isAtMost(q2ToDate!);
          });
          sum = 0;
          for (var target in curQtrSales.toList()) {
            sum += double.tryParse(target.total) ?? 0;
          }
          Q2Collection = sum;
          Q2CollectionStr = "${(Q2Collection / 100000).toStringAsFixed(2)} L";
          Q2Target += Q2Collection;
          Q2TargetStr = "${(Q2Target / 100000).toStringAsFixed(2)} L";
          if (Q2Collection == 0) {
            Q2Percentage = 0;
          } else {
            Q2Percentage =
                double.tryParse(
                  ((Q2Collection / (Q2Target == 0 ? Q2Collection : Q2Target)) *
                          100)
                      .toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q2PercentageStr = "${Q2Percentage.toString()}%";
          if (Q2Percentage > 100) {
            Q2Percentage = 100;
          }
          Q2Average = (Q2Collection / MonthDiffs);
          Q2AverageStr = "${(Q2Average / 100000).toStringAsFixed(2)} L";
          Q2DiffStr =
              "${((Q2Target - Q2Collection > 0 ? Q2Target - Q2Collection : 0) / 100000).toStringAsFixed(2)} L";
          break;
        case 3:
          sum = 0;
          MonthDiffs = monthDifference(q3FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q3FromDate!, currentDate!);
          var curQtrTarget = target.where((target) {
            DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
            return dueon.isAtMost(q3ToDate!);
          });
          sum = 0;
          for (var target in curQtrTarget.toList()) {
            if (double.tryParse(target.future)! <= 0) {
              sum += double.tryParse(target.balance) ?? 0;
            }
          }
          Q3Target = sum;
          var curQtrCollection = collection.where((target) {
            DateTime postingDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.postingDate);
            return postingDate.isAtLeast(q3FromDate!) &&
                postingDate.isAtMost(q3ToDate!);
          });
          sum = 0;
          for (var target in curQtrCollection.toList()) {
            sum += double.tryParse(target.total) ?? 0;
          }
          Q3Collection = sum;
          Q3CollectionStr = "${(Q3Collection / 100000).toStringAsFixed(2)} L";
          Q3Target += Q3Collection;
          Q3TargetStr = "${(Q3Target / 100000).toStringAsFixed(2)} L";
          if (Q3Collection == 0) {
            Q3Percentage = 0;
          } else {
            Q3Percentage =
                double.tryParse(
                  ((Q3Collection / (Q3Target == 0 ? Q3Collection : Q3Target)) *
                          100)
                      .toStringAsFixed(2),
                )?.ceil() ??
                0;
          }

          Q3PercentageStr = "${Q3Percentage.toString()}%";
          if (Q3Percentage > 100) {
            Q3Percentage = 100;
          }
          Q3Average = (Q3Collection / MonthDiffs);
          Q3AverageStr = "${(Q3Average / 100000).toStringAsFixed(2)} L";
          Q3DiffStr =
              "${((Q3Target - Q3Collection > 0 ? Q3Target - Q3Collection : 0) / 100000).toStringAsFixed(2)} L";
          break;
        case 4:
          sum = 0;
          MonthDiffs = monthDifference(q4FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q4FromDate!, currentDate!);
          var curQtrTarget = target.where((target) {
            DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
            return dueon.isAtMost(q4ToDate!);
          });
          sum = 0;
          for (var target in curQtrTarget.toList()) {
            if (double.tryParse(target.future)! <= 0) {
              sum += double.tryParse(target.balance) ?? 0;
            }
          }
          Q4Target = sum;
          var curQtrCollection = collection.where((target) {
            DateTime postingDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.postingDate);
            return postingDate.isAtLeast(q4FromDate!) &&
                postingDate.isAtMost(q4ToDate!);
          });
          sum = 0;
          for (var target in curQtrCollection.toList()) {
            sum += double.tryParse(target.total) ?? 0;
          }
          Q4Collection = sum;
          Q4CollectionStr = "${(Q4Collection / 100000).toStringAsFixed(2)} L";
          Q4Target += Q4Collection;
          Q4TargetStr = "${(Q4Target / 100000).toStringAsFixed(2)} L";
          if (Q4Collection == 0) {
            Q4Percentage = 0;
          } else {
            Q4Percentage =
                double.tryParse(
                  ((Q4Collection / (Q4Target == 0 ? Q4Collection : Q4Target)) *
                          100)
                      .toStringAsFixed(2),
                )?.ceil() ??
                0;
          }

          Q4PercentageStr = "${Q4Percentage.toString()}%";
          if (Q4Percentage > 100) {
            Q4Percentage = 100;
          }
          Q4Average = (Q4Collection / MonthDiffs);
          Q4AverageStr = "${(Q4Average / 100000).toStringAsFixed(2)} L";
          Q4DiffStr =
              "${((Q4Target - Q4Collection > 0 ? Q4Target - Q4Collection : 0) / 100000).toStringAsFixed(2)} L";
          break;
        default:
      }
    }
  }

  List<CollectionList> filterCollectionList(
    List<CollectionList> collectionList,
    List<Users> userNames, {
    String? regionalManager,
    String? salesManager,
    String? salesRep,
    String? customerCode,
    String? agingCategory,
  }) {
    bool regionalManagerCondition = true;
    bool salesManagerCondition = true;
    List<CollectionList> filteredCollectionList = [];
    for (var collection in collectionList) {
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
            childMenuNames.contains(collection.salesManager);
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
            childMenuNames.contains(collection.salesRep);
      }

      if (!regionalManagerCondition || !salesManagerCondition) {
        continue;
      }

      if ((salesRep == null ||
              salesRep.isEmpty ||
              collection.salesRep == salesRep) &&
          (customerCode == null ||
              customerCode.isEmpty ||
              collection.customerCode == customerCode)) {
        filteredCollectionList.add(collection);
      }
    }
    return filteredCollectionList;
  }

  List<DebtorsAgingList> filterCollectionTargetList(
    List<DebtorsAgingList> collectionTargetList,
    List<Users> userNames, {
    String? regionalManager,
    String? salesManager,
    String? salesRep,
    String? customerCode,
  }) {
    bool regionalManagerCondition = true;
    bool salesManagerCondition = true;
    List<DebtorsAgingList> filteredCollectionTargetList = [];

    for (var target in collectionTargetList) {
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
        continue;
      }
      if ((salesRep == null ||
              salesRep.isEmpty ||
              target.salesRep == salesRep) &&
          (customerCode == null ||
              customerCode.isEmpty ||
              target.customerCode == customerCode)) {
        filteredCollectionTargetList.add(target);
      }
    }
    return filteredCollectionTargetList;
  }

  Future<void> _loadReceivablesAgingData(
    int monthIndex,
    String touchedRegionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String touchedAgingCategory,
  ) async {
    List<ReceivablesAgingData> receivablesAgingDataList = [];
    double agingGroup1Total = 0;
    double agingGroup2Total = 0;
    double agingGroup3Total = 0;
    double agingGroup4Total = 0;
    double totalDueAmount = 0;

    var collectionTargetList = target.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
      return dueon.isAtMost(currentMonthToDate!);
    });

    AgingSummary summary = summarizeCollectionTargets(collectionTargetList);
    agingGroup1Total = summary.a0to30DaysTotal;
    agingGroup2Total = summary.a31to60DaysTotal;
    agingGroup3Total = summary.a61to90DaysTotal;
    agingGroup4Total = summary.a91to180DaysTotal + summary.a181DaysTotal;
    totalDueAmount =
        agingGroup1Total +
        agingGroup2Total +
        agingGroup3Total +
        agingGroup4Total;
    receivablesAgingDataList.add(
      ReceivablesAgingData(
        agingGroup: "0-30",
        agingGroupTotal: agingGroup1Total,
        agingPercentage: 0,
        agingTotal: totalDueAmount,
      ),
    );
    receivablesAgingDataList.add(
      ReceivablesAgingData(
        agingGroup: "31-60",
        agingGroupTotal: agingGroup2Total,
        agingPercentage: 0,
        agingTotal: totalDueAmount,
      ),
    );
    receivablesAgingDataList.add(
      ReceivablesAgingData(
        agingGroup: "61-90",
        agingGroupTotal: agingGroup3Total,
        agingPercentage: 0,
        agingTotal: totalDueAmount,
      ),
    );
    receivablesAgingDataList.add(
      ReceivablesAgingData(
        agingGroup: "90+",
        agingGroupTotal: agingGroup4Total,
        agingPercentage: 0,
        agingTotal: totalDueAmount,
      ),
    );

    for (ReceivablesAgingData agingData in receivablesAgingDataList) {
      agingData.agingPercentage =
          double.tryParse(
            ((agingData.agingGroupTotal / totalDueAmount) * 100)
                .toStringAsFixed(2),
          ) ??
          0;
      agingData.agingGroupTotal =
          double.tryParse((agingData.agingGroupTotal).toStringAsFixed(2)) ?? 0;
    }
    receivablesAgingList = ReceivablesAgingList(
      agingData: receivablesAgingDataList,
    );
  }

  Future<void> _loadMonthlyCollectionBarChartData(
    int monthIndex,
    String touchedRegionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String touchedAgingCategory,
  ) async {
    List<MonthlyCollectionData> monthlyDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    for (int i = 4; i <= 15; i++) {
      String monthName = getMonthName(i);
      double monthlyTarget = 0.00;
      double monthlyCollection = 0.00;

      var monthlyCollectionList = const Iterable.empty();
      if (i >= 4 && i <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(i);
        var currentMonthTarget = target.where((target) {
          DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
          return dueon.isAtMost(monthDates['end']!);
        });
        for (var target in currentMonthTarget.toList()) {
          double balance = double.tryParse(target.balance) ?? 0;
          monthlyTarget += balance;
        }

        monthlyCollectionList = collection.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, i - 12, 1);
        endDate = DateTime(currentYear, (i - 12) + 1, 0);

        var currentMonthTarget = target.where((target) {
          DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
          return dueon.isAtMost(endDate);
        });
        for (var target in currentMonthTarget.toList()) {
          double balance = double.tryParse(target.balance) ?? 0;
          monthlyTarget += balance;
        }

        monthlyCollectionList = collection.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        });
      }
      for (var target in monthlyCollectionList.toList()) {
        monthlyCollection += double.tryParse(target.total) ?? 0;
      }
      monthlyDataList.add(
        MonthlyCollectionData(
          monthName: monthName,
          collectionAmount: monthlyCollection,
          collectionTarget: monthlyTarget,
        ),
      );
      monthlyCollection = 0;
      monthlyTarget = 0;
    }
    monthlyCollectionList = MonthlyColectionList(monthlyData: monthlyDataList);
  }

  Future<void> _loadCustomerWiseCollectionBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String agingCategory,
  ) async {
    List<CustomerWiseCollectionData> customerWiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String custCode = "";
    String customerName = "";
    double customerCollection = 0.00;
    double customerTarget = 0.00;

    var customerCollectionList = const Iterable.empty();
    var customerTargetList = const Iterable.empty();
    setState(() {
      if (monthIndex == 0) {
        startDate = currentMonthFromDate!;
        endDate = currentDate!;

        customerTargetList = target.where((target) {
          DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
          return dueon.isAtMost(currentMonthToDate!);
        });

        customerCollectionList = collection.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        });
      } else {
        if (monthIndex >= 4 && monthIndex <= 12) {
          Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
          customerTargetList = target.where((target) {
            DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
            return dueon.isAtMost(monthDates['end']!);
          });

          customerCollectionList = collection.where((target) {
            DateTime postingDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.postingDate);
            return postingDate.isAtLeast(monthDates['start']!) &&
                postingDate.isAtMost(monthDates['end']!);
          });
        } else {
          startDate = DateTime(currentYear, monthIndex, 1);
          endDate = DateTime(currentYear, monthIndex + 1, 0);

          customerTargetList = target.where((target) {
            DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
            return dueon.isAtMost(endDate);
          });

          customerCollectionList = collection.where((target) {
            DateTime postingDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.postingDate);
            return postingDate.isAtLeast(startDate) &&
                postingDate.isAtMost(endDate);
          });
        }
      }
    });
    customerCollectionList = filterCollectionList(
      customerCollectionList.cast<CollectionList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      customerCode: customerCode,
      agingCategory: agingCategory,
    );
    customerTargetList = filterCollectionTargetList(
      customerTargetList.cast<DebtorsAgingList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      customerCode: customerCode,
    );

    Set<String> processedCustomerCodes = {};
    for (var customer
        in customerTargetList.toList()
          ..sort((a, b) => a.customerCode.compareTo(b.customerCode))) {
      if (!processedCustomerCodes.contains(customer.customerCode)) {
        custCode = customer.customerCode;
        customerName = customer.customerName;
        for (var collection in customerCollectionList.where(
          (element) => element.customerCode == custCode,
        )) {
          customerCollection += double.tryParse(collection.total) ?? 0;
        }
        for (var target in customerTargetList.where(
          (element) => element.customerCode == custCode,
        )) {
          double balance = double.tryParse(target.balance) ?? 0;
          customerTarget += balance;
        }
        customerWiseDataList.add(
          CustomerWiseCollectionData(
            customerCode: custCode,
            customerName: customerName,
            collectionAmount: customerCollection,
            targetAmount: customerTarget,
          ),
        );
        processedCustomerCodes.add(custCode);
      }
      customerCollection = 0;
      customerTarget = 0;
      custCode = "";
      customerName = "";
    }

    customerWiseDataList.sort(
      (a, b) => b.collectionAmount.compareTo(a.collectionAmount),
    );
    customerWiseCollectionList = CustomerWiseCollectionList(
      customerData: customerWiseDataList,
    );
  }

  Future<void> _loadTSMCollectionBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String agingCategory,
  ) async {
    List<TsmwiseCollectionData> tsmwiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String tsmName = "";
    double salesAmount = 0.00;
    double targetAmount = 0.00;

    var tsmCollectionList = const Iterable.empty();
    var tsmCollectionTargetList = const Iterable.empty();
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      tsmCollectionTargetList = target.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
        return dueon.isAtMost(currentMonthToDate!);
      });

      tsmCollectionList = collection.where((target) {
        DateTime postingDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.postingDate);
        return postingDate.isAtLeast(startDate) &&
            postingDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);

        tsmCollectionTargetList = target.where((target) {
          DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
          return dueon.isAtMost(monthDates['end']!);
        });

        tsmCollectionList = collection.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        tsmCollectionTargetList = target.where((target) {
          DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
          return dueon.isAtMost(endDate);
        });

        tsmCollectionList = collection.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        });
      }
    }

    tsmCollectionList = filterCollectionList(
      tsmCollectionList.cast<CollectionList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      customerCode: customerCode,
      agingCategory: agingCategory,
    );
    tsmCollectionTargetList = filterCollectionTargetList(
      tsmCollectionTargetList.cast<DebtorsAgingList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      customerCode: customerCode,
    );

    Set<String> processedTsmNames = {};
    for (var tsm in tsmCollectionList.toList()) {
      if (!processedTsmNames.contains(tsm.salesRep)) {
        tsmName = tsm.salesRep;
        for (var collection in tsmCollectionList.where(
          (tsmelement) => tsmelement.salesRep == tsmName,
        )) {
          salesAmount += double.tryParse(collection.total) ?? 0;
        }
        for (var target in tsmCollectionTargetList.where(
          (element) => element.salesRep == tsmName,
        )) {
          double balance = double.tryParse(target.balance) ?? 0;
          targetAmount += balance;
        }
        tsmwiseDataList.add(
          TsmwiseCollectionData(
            tsmName: tsmName,
            collectionAmount: salesAmount,
            targetAmount: targetAmount,
          ),
        );
        processedTsmNames.add(tsmName);
      }
      targetAmount = 0;
      salesAmount = 0;
      tsmName = "";
    }

    tsmwiseDataList.sort(
      (a, b) => a.collectionAmount.compareTo(b.collectionAmount),
    );
    tsmwiseCollectionList = TsmwiseCollectionList(tsmwiseData: tsmwiseDataList);
    if (listOfTSM.isEmpty) {
      listOfTSM = List<String>.from(
        tsmCollectionList.map((e) => e.regionalManager).toSet(),
      );
    }
  }

  Future<void> _loadASMCollectionBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String agingCategory,
  ) async {
    List<AsmwiseCollectionData> asmwiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String asmName = "";
    double salesAmount = 0.00;
    double targetAmount = 0.00;

    var asmCollectionList = const Iterable.empty();
    var asmCollectionTargetList = const Iterable.empty();
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;

      asmCollectionTargetList = target.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
        return dueon.isAtMost(currentMonthToDate!);
      });

      asmCollectionList = collection.where((target) {
        DateTime postingDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.postingDate);
        return postingDate.isAtLeast(startDate) &&
            postingDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);

        asmCollectionTargetList = target.where((target) {
          DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
          return dueon.isAtMost(monthDates['end']!);
        });

        asmCollectionList = collection.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        asmCollectionTargetList = target.where((target) {
          DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
          return dueon.isAtMost(endDate);
        });

        asmCollectionList = collection.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        });
      }
    }

    asmCollectionList = filterCollectionList(
      asmCollectionList.cast<CollectionList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      customerCode: customerCode,
      agingCategory: agingCategory,
    );
    asmCollectionTargetList = filterCollectionTargetList(
      asmCollectionTargetList.cast<DebtorsAgingList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      customerCode: customerCode,
    );

    Set<String> processedAsmNames = {};
    for (var tsm in asmCollectionList.toList()) {
      if (!processedAsmNames.contains(tsm.salesManager)) {
        asmName = tsm.salesManager;
        for (var collection in asmCollectionList.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          salesAmount += double.tryParse(collection.total) ?? 0;
        }
        for (var target in asmCollectionTargetList.where(
          (element) => element.salesManager == asmName,
        )) {
          double balance = double.tryParse(target.balance) ?? 0;
          targetAmount += balance;
        }

        asmwiseDataList.add(
          AsmwiseCollectionData(
            asmName: asmName,
            collectionAmount: salesAmount,
            targetAmount: targetAmount,
          ),
        );
        processedAsmNames.add(asmName);
      }
      targetAmount = 0;
      salesAmount = 0;
      asmName = "";
    }

    asmwiseDataList.sort(
      (a, b) => a.collectionAmount.compareTo(b.collectionAmount),
    );
    asmwiseCollectionList = AsmwiseCollectionList(asmwiseData: asmwiseDataList);
    if (listOfASM.isEmpty) {
      listOfASM = List<String>.from(
        asmCollectionList.map((e) => e.regionalManager).toSet(),
      );
    }
  }

  Future<void> _loadRSMCollectionBarChartData(
    int monthIndex,
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String agingCategory,
  ) async {
    List<RsmwiseCollectionData> rsmwiseDataList = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String rsmName = "";
    int rsmId = 0;
    int asmId = 0;
    double salesAmount = 0.00;
    double targetAmount = 0.00;

    var rsmCollectionList = const Iterable.empty();
    var rsmCollectionTargetList = const Iterable.empty();
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;

      rsmCollectionTargetList = target.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
        return dueon.isAtMost(currentMonthToDate!);
      });

      rsmCollectionList = collection.where((target) {
        DateTime postingDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.postingDate);
        return postingDate.isAtLeast(startDate) &&
            postingDate.isAtMost(endDate);
      });
    } else {
      if (monthIndex >= 4 && monthIndex <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);

        rsmCollectionTargetList = target.where((target) {
          DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
          return dueon.isAtMost(monthDates['end']!);
        });

        rsmCollectionList = collection.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, monthIndex, 1);
        endDate = DateTime(currentYear, monthIndex + 1, 0);

        rsmCollectionTargetList = target.where((target) {
          DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
          return dueon.isAtMost(endDate);
        });

        rsmCollectionList = collection.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        });
      }
    }

    rsmCollectionList = filterCollectionList(
      rsmCollectionList.cast<CollectionList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      customerCode: customerCode,
      agingCategory: agingCategory,
    );
    rsmCollectionTargetList = filterCollectionTargetList(
      rsmCollectionTargetList.cast<DebtorsAgingList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesRep,
      customerCode: customerCode,
    );

    Set<String> processedRsmNames = {};
    List<AsmMenu> asmNames = [];
    List<String> tsmNames = [];
    if (int.tryParse(UserLevel)! > 3) {
      List<RsmMenu> rsmMenuNames = usersList
          .where(
            (element) => element.parentMenuId == 0 && element.userLevel == 3,
          )
          .map((user) => RsmMenu(user.menuName, user.menuId))
          .toList();
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
            for (var collection in rsmCollectionList.where(
              (tsmelement) => tsmNames.contains(tsmelement.salesRep),
            )) {
              salesAmount += double.tryParse(collection.total) ?? 0;
            }
            for (var target in rsmCollectionTargetList.where(
              (element) => tsmNames.contains(element.salesRep),
            )) {
              double balance = double.tryParse(target.balance) ?? 0;
              targetAmount += balance;
            }
          }

          if (salesAmount + targetAmount > 0) {
            rsmwiseDataList.add(
              RsmwiseCollectionData(
                rsmName: rsmName,
                collectionAmount: salesAmount,
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
    rsmwiseCollectionList = RsmwiseCollectionList(rsmwiseData: rsmwiseDataList);
    if (listOfRSM.isEmpty) {
      listOfRSM = List<String>.from(
        rsmCollectionList.map((e) => e.regionalManager).toSet(),
      );
    }
  }

  Future<void> _loadReceivablesCategoryData() async {
    List<ReceivablesCategoryData> receivablesCategoryDataList = [];
    int categoryId = 0;
    String categoryName = "";
    double categoryAmount = 0;

    var collectionTargetList = const Iterable.empty();

    collectionTargetList = target.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
      return dueon.isAtMost(currentMonthToDate!);
    });

    Set<String> processedCategory = {};
    for (var category in collectionTargetList.toList()) {
      if (!processedCategory.contains(category.customerGroup)) {
        categoryName = category.customerGroup;
        for (var target in collectionTargetList.where(
          (element) => element.customerGroup == categoryName,
        )) {
          double balance = double.tryParse(target.balance) ?? 0;
          double future = double.tryParse(target.future) ?? 0;
          if (future <= 0) {
            categoryAmount += balance;
          }
        }
        if (categoryAmount > 0) {
          receivablesCategoryDataList.add(
            ReceivablesCategoryData(
              categoryId: categoryId++,
              categoryName: categoryName == "" ? "Others" : categoryName,
              categoryAmount: categoryAmount,
              categoryPercentage: 0,
            ),
          );
          processedCategory.add(categoryName);
        }
      }
      categoryAmount = 0;
      categoryName = "";
    }
    double totalAmount = receivablesCategoryDataList.fold(
      0,
      (double previousValue, ReceivablesCategoryData element) =>
          previousValue + element.categoryAmount,
    );
    for (ReceivablesCategoryData categoryData in receivablesCategoryDataList) {
      categoryData.categoryPercentage =
          double.tryParse(
            ((categoryData.categoryAmount / totalAmount) * 100).toStringAsFixed(
              2,
            ),
          ) ??
          0;
      categoryData.categoryAmount =
          double.tryParse(
            (categoryData.categoryAmount / 100000).toStringAsFixed(2),
          ) ??
          0;
    }
    receivablesCategoryList = ReceivablesCategoryList(
      categoryData: receivablesCategoryDataList,
    );
  }

  AgingSummary summarizeCollectionTargetsOld(
    Iterable<DebtorsAgingList> collectionTargetList,
  ) {
    AgingSummary summary = AgingSummary();
    double balance = 0;
    for (var element in collectionTargetList.where(
      (element) => double.tryParse(element.future)! <= 0,
    )) {
      balance = double.tryParse(element.a0to30Days) ?? 0;
      if (balance < 0) {
        balance = 0; // If balance is negative, set it to zero
      }
      summary.a0to30DaysTotal += balance;
      balance = double.tryParse(element.a31to60Days) ?? 0;
      if (balance < 0) {
        balance = 0;
      }
      summary.a31to60DaysTotal += balance;
      balance = double.tryParse(element.a61to90Days) ?? 0;
      if (balance < 0) {
        balance = 0;
      }
      summary.a61to90DaysTotal += balance;
      balance = double.tryParse(element.a91to180Days) ?? 0;
      if (balance < 0) {
        balance = 0;
      }
      summary.a91to180DaysTotal += balance;
      balance = double.tryParse(element.a181Days) ?? 0;
      if (balance < 0) {
        balance = 0;
      }
      summary.a181DaysTotal += balance;
    }
    return summary;
  }

  AgingSummary summarizeCollectionTargets(
    Iterable<DebtorsAgingList> collectionTargetList,
  ) {
    AgingSummary summary = AgingSummary();
    double balance = 0;
    var overDueDays = 0;
    for (var element in collectionTargetList.where(
      (element) => double.tryParse(element.future)! <= 0,
    )) {
      overDueDays = int.tryParse(element.dueDays.replaceAll(' Days', '')) ?? 0;
      balance = double.tryParse(element.balance) ?? 0;
      if (balance < 0) {
        // balance = 0; // If balance is negative, set it to zero
      }
      if (overDueDays <= 30) {
        summary.a0to30DaysTotal += balance;
      } else if (overDueDays >= 31 && overDueDays <= 60) {
        summary.a31to60DaysTotal += balance;
      } else if (overDueDays >= 61 && overDueDays <= 90) {
        summary.a61to90DaysTotal += balance;
      } else if (overDueDays >= 91) {
        summary.a91to180DaysTotal += balance;
      }
    }
    return summary;
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;
      LastMonthTarget = 0;
      CurrentQtrTarget = 0;
      YtdTarget = 0;
      Q1Target = 0;
      Q1Diff = 0;
      Q1Percentage = 0;
      Q1TargetStr = "";
      Q1DiffStr = "";
      Q1PercentageStr = "";
      Q2Target = 0;
      Q2Diff = 0;
      Q2Percentage = 0;
      Q2TargetStr = "";
      Q2DiffStr = "";
      Q2PercentageStr = "";
      Q3Target = 0;
      Q3Diff = 0;
      Q3Percentage = 0;
      Q3TargetStr = "";
      Q3DiffStr = "";
      Q3PercentageStr = "";
      Q4Target = 0;
      Q4Diff = 0;
      Q4Percentage = 0;
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
      ytdCollectionList = YTDCollectionList(ytdColData: []);
      monthlyCollectionList = MonthlyColectionList(monthlyData: []);
      customerWiseCollectionList = CustomerWiseCollectionList(customerData: []);
      tsmwiseCollectionList = TsmwiseCollectionList(tsmwiseData: []);
      asmwiseCollectionList = AsmwiseCollectionList(asmwiseData: []);
      rsmwiseCollectionList = RsmwiseCollectionList(rsmwiseData: []);
      receivablesCategoryList = ReceivablesCategoryList(categoryData: []);
      receivablesAgingList = ReceivablesAgingList(agingData: []);
      touchedMonthIndex = 0;
    });
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
    touchedAgingCategory = "";
    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;
    LoadDates();
    LoadAllQuarterFromToDates();
    final prefs = await SharedPreferences.getInstance();
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
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
    String touchedRegionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String touchedAgingCategory,
  ) async {
    LoadDates();
    LoadAllQuarterFromToDates();
    final prefs = await SharedPreferences.getInstance();
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    showDrillDownChart = true;
    showProductSaleChart = true;
    await _loadReceivablesAgingData(
      monthIndex,
      touchedRegionalManager,
      salesManager,
      salesRep,
      customerCode,
      touchedAgingCategory,
    );
    await _loadMonthlyCollectionBarChartData(
      monthIndex,
      touchedRegionalManager,
      salesManager,
      salesRep,
      customerCode,
      touchedAgingCategory,
    );
    await _loadCustomerWiseCollectionBarChartData(
      monthIndex,
      touchedRegionalManager,
      salesManager,
      salesRep,
      customerCode,
      touchedAgingCategory,
    );
    if (UserLevel != "1") {
      await _loadTSMCollectionBarChartData(
        monthIndex,
        touchedRegionalManager,
        salesManager,
        salesRep,
        customerCode,
        touchedAgingCategory,
      );
      await _loadASMCollectionBarChartData(
        monthIndex,
        touchedRegionalManager,
        salesManager,
        salesRep,
        customerCode,
        touchedAgingCategory,
      );
      await _loadRSMCollectionBarChartData(
        monthIndex,
        touchedRegionalManager,
        salesManager,
        salesRep,
        customerCode,
        touchedAgingCategory,
      );
    }
    chartDataLoaded = true;
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
    await _loadCollectionTarget(userName, userLevel);
    await _loadCollection(userName, userLevel);
    await _loadEachQtrValues();
    await _loadReceivablesAgingData(0, "", "", "", "", "");
    await _loadMonthlyCollectionBarChartData(0, "", "", "", "", "");
    await _loadCustomerWiseCollectionBarChartData(0, "", "", "", "", "");
    if (UserLevel != "1") {
      await _loadTSMCollectionBarChartData(0, "", "", "", "", "");
      await _loadASMCollectionBarChartData(0, "", "", "", "", "");
      await _loadRSMCollectionBarChartData(0, "", "", "", "", "");
    }
    await _loadReceivablesCategoryData();
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
      chartDataLoaded = true;
    });
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
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
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

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> generateReceivablesAgingExcel(
    ReceivablesAgingList agingData,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Group Name', 'Amount']));
      for (var itemData in agingData.agingData) {
        sheet.appendRow(
          toCellRow([itemData.agingGroup, itemData.agingGroupTotal]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'receivables_aging.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('receivables_aging.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/receivables_aging.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateReceivablesAgingPDF(
    ReceivablesAgingList agingData,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Receivables Aging',
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
      final totalPages = (agingData.agingData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > agingData.agingData.length
            ? agingData.agingData.length
            : start + rowsPerPage;
        final tableData = agingData.agingData.sublist(start, end);

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
                        'Group',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Amount',
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
        // html.window.open(url, '_blank');
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/receivables_aging.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthWiseCollectionAnalysisExcel(
    MonthlyColectionList monthlySalesList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Month',
          'Sales Amount',
          'Sales Target',
          'Percentage',
          'Difference',
        ]),
      );
      for (var monthlyData in monthlySalesList.monthlyData) {
        sheet.appendRow(
          toCellRow([
            monthlyData.monthName,
            monthlyData.collectionAmount,
            monthlyData.collectionTarget,
            ((monthlyData.collectionAmount / monthlyData.collectionTarget == 0
                        ? monthlyData.collectionAmount
                        : monthlyData.collectionTarget) *
                    100)
                .ceil()
                .toStringAsFixed(0),
            monthlyData.collectionAmount - monthlyData.collectionTarget,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'monthWise_collection_analysis.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthWise_collection_analysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthWise_collection_analysis.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthWiseCollectionAnalysisPDF(
    MonthlyColectionList monthlySalesList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Monthwise Collection Analysis',
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
                        monthlyData.collectionAmount.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.collectionTarget.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        ((monthlyData.collectionAmount /
                                            monthlyData.collectionTarget ==
                                        0
                                    ? monthlyData.collectionAmount
                                    : monthlyData.collectionTarget) *
                                100)
                            .ceil()
                            .toStringAsFixed(0),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.collectionAmount -
                                monthlyData.collectionTarget)
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
        // html.window.open(url, '_blank');
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_sales_report_SO_Analysis.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateCustomerAnalysisCollectionExcel(
    CustomerWiseCollectionList customerWiseSalesList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Customer Name',
          'Sales Amount',
          'Sales Target',
          'Percentage',
          'Difference',
        ]),
      );
      for (var customerData in customerWiseSalesList.customerData) {
        sheet.appendRow(
          toCellRow([
            customerData.customerName,
            customerData.collectionAmount,
            customerData.targetAmount,
            ((customerData.collectionAmount / customerData.targetAmount == 0
                        ? customerData.collectionAmount
                        : customerData.targetAmount) *
                    100)
                .ceil()
                .toStringAsFixed(0),
            customerData.collectionAmount - customerData.targetAmount,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'customer_collection_analysis.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('customer_collection_analysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/customer_collection_analysis.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateCustomerAnalysisCollectionPDF(
    CustomerWiseCollectionList customerWiseSalesList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Customer Analysis - Collection',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20; // Number of rows per page
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
                          monthlyData.collectionAmount.toString(),
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
                          ((monthlyData.collectionAmount /
                                              monthlyData.targetAmount !=
                                          0
                                      ? monthlyData.targetAmount
                                      : monthlyData.collectionAmount) *
                                  100)
                              .ceil()
                              .toStringAsFixed(0),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          (monthlyData.collectionAmount -
                                  monthlyData.targetAmount)
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
        // html.window.open(url, '_blank');
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File(
          '$storageDir/customerwise_sales_report_SO_Analysis.pdf',
        );
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesManagerAnalysisCollectionExcel(
    AsmwiseCollectionList asmwiseSalesList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Name',
          'Sales Amount',
          'Sales Target',
          'Percentage',
          'Difference',
        ]),
      );
      for (var asmData in asmwiseSalesList.asmwiseData) {
        sheet.appendRow(
          toCellRow([
            asmData.asmName,
            asmData.collectionAmount,
            asmData.targetAmount,
            ((asmData.collectionAmount / asmData.targetAmount == 0
                        ? asmData.collectionAmount
                        : asmData.targetAmount) *
                    100)
                .ceil()
                .toStringAsFixed(0),
            asmData.collectionAmount - asmData.targetAmount,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'sales_manager_analysis_collection.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('sales_manager_analysis_collection.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/sales_manager_analysis_collection.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesManagerAnalysisCollectionPDF(
    AsmwiseCollectionList asmwiseSalesList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Sales Manager Analysis - Collection',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20; // Number of rows per page
      final totalPages = (asmwiseSalesList.asmwiseData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > asmwiseSalesList.asmwiseData.length
            ? asmwiseSalesList.asmwiseData.length
            : start + rowsPerPage;
        final tableData = asmwiseSalesList.asmwiseData.sublist(start, end);

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
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
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
                          monthlyData.collectionAmount.toString(),
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
        // html.window.open(url, '_blank');
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File(
          '$storageDir/salesmanager_sales_report_SO_Analysis.pdf',
        );
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesPersonAnalysisCollectionExcel(
    TsmwiseCollectionList tsmwiseSalesList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Name',
          'Sales Amount',
          'Sales Target',
          'Percentage',
          'Difference',
        ]),
      );
      for (var tsmData in tsmwiseSalesList.tsmwiseData) {
        sheet.appendRow(
          toCellRow([
            tsmData.tsmName,
            tsmData.collectionAmount,
            tsmData.targetAmount,
            ((tsmData.collectionAmount / tsmData.targetAmount == 0
                        ? tsmData.collectionAmount
                        : tsmData.targetAmount) *
                    100)
                .ceil()
                .toStringAsFixed(0),
            tsmData.collectionAmount - tsmData.targetAmount,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'sales_person_analysis_collection.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('sales_person_analysis_collection.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/sales_person_analysis_collection.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesPersonAnalysisCollectionPDF(
    TsmwiseCollectionList tsmwiseSalesList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Sales Person Analysis - Collection',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20; // Number of rows per page
      final totalPages = (tsmwiseSalesList.tsmwiseData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > tsmwiseSalesList.tsmwiseData.length
            ? tsmwiseSalesList.tsmwiseData.length
            : start + rowsPerPage;
        final tableData = tsmwiseSalesList.tsmwiseData.sublist(start, end);

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
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
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
                          monthlyData.collectionAmount.toString(),
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
        // html.window.open(url, '_blank');
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File(
          '$storageDir/sale_person_sales_report_collection.pdf',
        );
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateReceivablesCategoryCollectionExcel(
    ReceivablesCategoryList dataList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Name', 'Sales Amount', 'Percentage']));
      for (var data in dataList.categoryData) {
        sheet.appendRow(
          toCellRow([
            data.categoryName,
            data.categoryAmount,
            data.categoryPercentage,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'receivables_category_collection.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('receivables_category_collection.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/receivables_category_collection.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateReceivablesCategoryCollectionPDF(
    ReceivablesCategoryList dataList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Receivables Category Wise Analysis',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20; // Number of rows per page
      final totalPages = (dataList.categoryData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > dataList.categoryData.length
            ? dataList.categoryData.length
            : start + rowsPerPage;
        final tableData = dataList.categoryData.sublist(start, end);

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
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.categoryName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.categoryAmount.toString(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.categoryPercentage.toString(),
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
        // html.window.open(url, '_blank');
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File(
          '$storageDir/sale_person_sales_report_collection.pdf',
        );
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateRsmCollectionExcel(
    RsmwiseCollectionList rsmwiseSalesList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Name',
          'Sales Amount',
          'Sales Target',
          'Percentage',
          'Difference',
        ]),
      );
      for (var rsmData in rsmwiseSalesList.rsmwiseData) {
        sheet.appendRow(
          toCellRow([
            rsmData.rsmName,
            rsmData.collectionAmount,
            rsmData.targetAmount,
            ((rsmData.collectionAmount / rsmData.targetAmount) * 100)
                .ceil()
                .toStringAsFixed(0),
            rsmData.collectionAmount - rsmData.targetAmount,
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'regionalmanager_sales_report.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);

        final excelBytes = excel.encode()!;
        saveAndOpenExcel('regionalmanager_sales_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/regionalmanager_sales_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateRsmCollectionPDF(
    RsmwiseCollectionList rsmwiseSalesList,
  ) async {
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
                        monthlyData.collectionAmount.toString(),
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
                        ((monthlyData.collectionAmount /
                                    monthlyData.targetAmount) *
                                100)
                            .ceil()
                            .toStringAsFixed(0),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        (monthlyData.collectionAmount -
                                monthlyData.targetAmount)
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
        // html.window.open(url, '_blank');
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/regionalmanager_sales_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateCollectionAnalysisExcel() async {
    await _loadYtdCollectionBarChartData();
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow([
        'Customer Name',
        'Sales Manager',
        'Sales Representative',
        'Apr Value',
        'May Value',
        'Jun Value',
        'Jul Value',
        'Aug Value',
        'Sep Value',
        'Oct Value',
        'Nov Value',
        'Dec Value',
        'Jan Value',
        'Feb Value',
        'Mar Value',
        'YTD Total Value',
      ]),
    );

    for (int column = 0; column < 16; column++) {
      var cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
      );
      cell.cellStyle = xl.CellStyle(bold: true, fontSize: 14);

      // sheet.setColAutoFit(column);
    }

    for (var colData in ytdCollectionList.ytdColData) {
      sheet.appendRow(
        toCellRow([
          colData.customerName,
          colData.salesManager,
          colData.salesRep,
          colData.aprValue,
          colData.mayValue,
          colData.junValue,
          colData.julValue,
          colData.augValue,
          colData.sepValue,
          colData.octValue,
          colData.novValue,
          colData.decValue,
          colData.janValue,
          colData.febValue,
          colData.marValue,
          colData.ytdTotalValue,
          xl.CellStyle(),
        ]),
      );
    }

    xl.CellStyle centerCellStyle = xl.CellStyle(
      verticalAlign: xl.VerticalAlign.Center,
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    int numberOfRows = ytdCollectionList.ytdColData.length;

    for (int rowIndex = 0; rowIndex <= numberOfRows; rowIndex++) {
      for (int colIndex = 0; colIndex < 16; colIndex++) {
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
      YtdColBarChartData = true;
    });
    if (kIsWeb) {
      // var fileBytes = excel.encode();
      // final blob = html.Blob([fileBytes]);
      // final url = html.Url.createObjectUrlFromBlob(blob);
      // final anchor = html.AnchorElement()
      //   ..href = url
      //   ..download = 'YTD_CollectionAnalysis_Report.xlsx'
      //   ..style.display = 'none';
      // html.document.body!.append(anchor);
      // anchor.click();
      // anchor.remove();
      // html.Url.revokeObjectUrl(url);

      final excelBytes = excel.encode()!;
      saveAndOpenExcel('YTD_CollectionAnalysis_Report.xlsx', excelBytes);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/YTD_CollectionAnalysis_Report.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> _loadYtdCollectionBarChartData() async {
    List<YTDCollectionData> ytdCollectionDataList = [];
    String custCode = "";
    String custName = "";
    String salesManager = "";
    String salesRep = "";
    DateTime startDate;
    DateTime endDate;

    List<CollectionList> tmpCollection = [];
    var ytdList = const Iterable.empty();

    Set<String> processedCustomerCodes = {};
    tmpCollection = collection.toList();
    for (var customer in tmpCollection.toList()) {
      if (!processedCustomerCodes.contains(customer.customerCode)) {
        salesManager = customer.salesManager;
        salesRep = customer.salesRep;
        custCode = customer.customerCode;
        custName = customer.customerName;

        List<double> monthlyValue = List.filled(12, 0.0);

        for (int i = 0; i <= 11; i++) {
          startDate = addMonth(fiscalYearStartDate!, i);
          endDate = addMonth(startDate, i + 1).add(const Duration(days: -1));
          setState(() {
            ytdList = tmpCollection.where((target) {
              DateTime postingDate = DateFormat(
                'dd/MM/yyyy',
              ).parse(target.postingDate);
              return target.customerCode == custCode &&
                  postingDate.isAtLeast(startDate) &&
                  postingDate.isAtMost(endDate);
            });
          });

          for (var col in ytdList.toList()) {
            double rowTotal = double.tryParse(col.total) ?? 0.0;
            monthlyValue[i] += rowTotal;
          }
        }
        ytdCollectionDataList.add(
          YTDCollectionData(
            customerName: custName,
            salesManager: salesManager,
            salesRep: salesRep,
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
          ),
        );
      }
      processedCustomerCodes.add(custCode);
      tmpCollection.removeWhere((col) => col.customerCode == custCode);
      custCode = "";
      custName = "";
    }
    setState(() {
      ytdCollectionDataList.sort(
        (a, b) => a.customerName.compareTo(b.customerName),
      );
      ytdCollectionList = YTDCollectionList(ytdColData: ytdCollectionDataList);
      YtdColBarChartData = true;
    });
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
      List<String> menuNames = usersList
          .where((element) => element.parentMenuId == 0)
          .map((user) => user.menuName)
          .toList();
      menuNames.insert(0, UserName);
      context
          .read<CollectionListCollectionsAnalysisBIProvider>()
          .updateCollectionList(collection);

      collection = collection.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
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
      await _loadCollectionTarget(userName, userLevel);
      await _loadCollection(userName, userLevel);
      _dateFilterTarget("", "", false);
      await _loadEachQtrValues();
      await _loadReceivablesAgingData(0, "", "", "", "", "");
      await _loadMonthlyCollectionBarChartData(0, "", "", "", "", "");
      await _loadCustomerWiseCollectionBarChartData(0, "", "", "", "", "");
      if (UserLevel != "1") {
        await _loadTSMCollectionBarChartData(0, "", "", "", "", "");
        await _loadASMCollectionBarChartData(0, "", "", "", "", "");
        await _loadRSMCollectionBarChartData(0, "", "", "", "", "");
      }
      await _loadReceivablesCategoryData();

      List<String> trueRSMOptions = (allCategoriesState['RSM'] ?? {}).entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      List<String> trueASMOptions = (allCategoriesState['ASM'] ?? {}).entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      List<String> trueTSMOptions = (allCategoriesState['TSM'] ?? {}).entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      List<CollectionList> filteredList = [];

      if (trueRSMOptions.isNotEmpty) {
        filteredList = collection
            .where((person) => trueRSMOptions.contains(person.regionalManager))
            .toList();
        collection = filteredList;
      }

      if (trueASMOptions.isNotEmpty) {
        filteredList = collection
            .where((person) => trueASMOptions.contains(person.salesManager))
            .toList();
        collection = filteredList;
      }

      if (trueTSMOptions.isNotEmpty) {
        filteredList = collection
            .where((person) => trueTSMOptions.contains(person.salesRep))
            .toList();
        collection = filteredList;
      }

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
    chartDataLoaded = false;
    LoadDates();
    LoadAllQuarterFromToDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
      toDateFilter = currentDate;
      fromDateFilter = fiscalYearStartDate;
    }

    filterOptions = [listOfRSM, listOfASM, listOfTSM, []];

    selectedFinanceReceivablesOptions = filterOptions
        .map((options) => List<bool>.filled(options.length, false))
        .toList();

    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
  }

  @override
  void dispose() {
    monthlyCollectionList = MonthlyColectionList(monthlyData: []);
    customerWiseCollectionList = CustomerWiseCollectionList(customerData: []);
    tsmwiseCollectionList = TsmwiseCollectionList(tsmwiseData: []);
    asmwiseCollectionList = AsmwiseCollectionList(asmwiseData: []);
    receivablesCategoryList = ReceivablesCategoryList(categoryData: []);
    receivablesAgingList = ReceivablesAgingList(agingData: []);
    UserLevel = "0";
    touchedMonth = "";
    maxMonthY = 0.0;
    barChartWidthProduct = 0.0;
    maxItemMonthY = 0.0;
    selectedChart = 0;
    userList = [];
    collectionsTargetList = [];
    Collections = 0;
    CollectionsStr = "";
    CollectionsGoalStr = "";
    CollectionPercentage = 0;
    CollectionPercentageStr = "";
    CurrentMonthCollectionsStr = "";
    CurrentMonthCollections = 0;
    CollectionGoal = 0;
    LastMonthCollections = 0;
    LastMonthCollectionsStr = "";
    LastMonthTarget = 0;
    LastMonthTargetStr = "";
    LastMonthPercentage = 0;
    CurrentQtrCollections = 0;
    CurrentQtrCollectionsStr = "";
    CurrentQtrTarget = 0;
    CurrentQtrTargetStr = "";
    CurrentQtrPercentage = 0;
    YtdCollections = 0;
    YtdCollectionsStr = "";
    YtdTarget = 0;
    YtdTargetStr = "";
    YtdPercentage = 0;
    CurrentMonthCollectionsPercentage = 0;
    CurrentMonthCollectionsPercentageStr = "";
    LastMonthPercentageStr = "";
    CurrentQtrPercentageStr = "";
    YtdPercentageStr = "";
    collectionList = [];
    collection = [];
    target = [];
    collectionsList = [];
    noUserList = false;
    chartDataLoaded = false;
    financialYear = "";
    prevFinancialYear = "";
    selectedProduct = 0;
    currentQuarter = 0;
    Q1Collection = 0;
    Q1Target = 0;
    Q1Diff = 0;
    Q1Percentage = 0;
    Q1CollectionStr = "";
    Q1TargetStr = "";
    Q1DiffStr = "";
    Q1PercentageStr = "";
    Q2Collection = 0;
    Q2Target = 0;
    Q2Diff = 0;
    Q2Percentage = 0;
    Q2CollectionStr = "";
    Q2TargetStr = "";
    Q2DiffStr = "";
    Q2PercentageStr = "";
    Q3Collection = 0;
    Q3Target = 0;
    Q3Diff = 0;
    Q3Percentage = 0;
    Q3CollectionStr = "";
    Q3TargetStr = "";
    Q3DiffStr = "";
    Q3PercentageStr = "";
    Q4Collection = 0;
    Q4Target = 0;
    Q4Diff = 0;
    Q4Percentage = 0;
    Q4CollectionStr = "";
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
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
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    showLoaderDialog(context);
                                    generateCollectionAnalysisExcel();
                                    if (YtdColBarChartData == true) {
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
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Collection Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(children: [SizedBox(width: 5)]),
                  ],
                ),
                SizedBox(
                  height: screenHeight / 2.67,
                  child: Stack(
                    children: [
                      Center(
                        child: CircularPercentIndicator(
                          arcType: ArcType.HALF,
                          radius: 120.0,
                          lineWidth: 50.0,
                          animation: true,
                          percent: CollectionPercentage / 100,
                          center: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 70.0),
                                child: Text(
                                  CollectionPercentageStr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              Text(
                                CollectionsStr,
                                style: const TextStyle(fontSize: 14.0),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${getMonthName(currentDate!.month)} Goal - $CollectionsGoalStr",
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
                        top: screenHeight / 4.5,
                        left: screenHeight / 35,
                        child: SizedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4.0,
                                  right: 4.0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
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
                                          LastMonthCollectionsStr,
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
                                            "${getMonthName(currentDate!.month - 1)} Collection \n($LastMonthTargetStr)",
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
                                          CurrentQtrCollectionsStr,
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
                                          "Q$currentQuarter Collection \n($CurrentQtrTargetStr)",
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
                                          YtdCollectionsStr,
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
                SingleChildScrollView(
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
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Column(
                                children: [
                                  Text("Target : $Q1TargetStr"),
                                  Text("Achieved : $Q1CollectionStr"),
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
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Column(
                                children: [
                                  Text("Target : $Q2TargetStr"),
                                  Text("Achieved : $Q2CollectionStr"),
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
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Column(
                                children: [
                                  Text("Target : $Q3TargetStr"),
                                  Text("Achieved : $Q3CollectionStr"),
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
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Column(
                                children: [
                                  Text("Target : $Q4TargetStr"),
                                  Text("Achieved : $Q4CollectionStr"),
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
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
                          "Receivables Aging",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateReceivablesAgingExcel(
                                      receivablesAgingList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateReceivablesAgingPDF(
                                      receivablesAgingList,
                                    );
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _receivablesAging(),
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
                          "MonthWise Collection \nAnalysis",
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
                          color: const Color(0xFF6CCC3F),
                        ),
                        const SizedBox(width: 5),
                        const Text("Target", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFF49136),
                        ),
                        const SizedBox(width: 5),
                        const Text("Collected", style: TextStyle(fontSize: 12)),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthWiseCollectionAnalysisExcel(
                                      monthlyCollectionList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthWiseCollectionAnalysisPDF(
                                      monthlyCollectionList,
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
                  child: _monthlyWiseCollectionAnalysis(),
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
                          color: const Color(0xFF78E25D),
                        ),
                        const SizedBox(width: 5),
                        const Text("Target", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFF49136),
                        ),
                        const SizedBox(width: 5),
                        const Text("Collected", style: TextStyle(fontSize: 12)),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateCustomerAnalysisCollectionExcel(
                                      customerWiseCollectionList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateCustomerAnalysisCollectionPDF(
                                      customerWiseCollectionList,
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
                  child: _customerAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Visibility(
                  visible: rsmwiseCollectionList.rsmwiseData.isNotEmpty,
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
                          const Text("Target", style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Container(
                            height: 8,
                            width: 8,
                            color: const Color(0xFFF49136),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Collected",
                            style: TextStyle(fontSize: 12),
                          ),
                          PopupMenuButton(
                            onSelected: (value) {},
                            itemBuilder: (BuildContext bc) {
                              return [
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateRsmCollectionExcel(
                                        rsmwiseCollectionList,
                                      );
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateRsmCollectionPDF(
                                        rsmwiseCollectionList,
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: rsmwiseCollectionList.rsmwiseData.isEmpty
                      ? const SizedBox.shrink()
                      : _regionalManagerAnalysis(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: rsmwiseCollectionList.rsmwiseData.isEmpty
                      ? const SizedBox.shrink()
                      : const Divider(thickness: 2),
                ),
                Visibility(
                  visible: asmwiseCollectionList.asmwiseData.isNotEmpty,
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
                          const Text("Target", style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Container(
                            height: 8,
                            width: 8,
                            color: const Color(0xFFF49136),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Collected",
                            style: TextStyle(fontSize: 12),
                          ),
                          PopupMenuButton(
                            onSelected: (value) {},
                            itemBuilder: (BuildContext bc) {
                              return [
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateSalesManagerAnalysisCollectionExcel(
                                        asmwiseCollectionList,
                                      );
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateSalesManagerAnalysisCollectionPDF(
                                        asmwiseCollectionList,
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: asmwiseCollectionList.asmwiseData.isEmpty
                      ? const SizedBox.shrink()
                      : _salesManagerAnalysis(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: asmwiseCollectionList.asmwiseData.isEmpty
                      ? const SizedBox.shrink()
                      : const Divider(thickness: 2),
                ),
                Visibility(
                  visible: asmwiseCollectionList.asmwiseData.isNotEmpty,
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
                          const Text("Target", style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Container(
                            height: 8,
                            width: 8,
                            color: const Color(0xFFF49136),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Collected",
                            style: TextStyle(fontSize: 12),
                          ),
                          PopupMenuButton(
                            onSelected: (value) {},
                            itemBuilder: (BuildContext bc) {
                              return [
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateSalesPersonAnalysisCollectionExcel(
                                        tsmwiseCollectionList,
                                      );
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateSalesPersonAnalysisCollectionPDF(
                                        tsmwiseCollectionList,
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: tsmwiseCollectionList.tsmwiseData.isEmpty
                      ? const SizedBox.shrink()
                      : _salesPersonAnalysis(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: tsmwiseCollectionList.tsmwiseData.isEmpty
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
                          "Receivables Category wise Analysis",
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
                                    generateReceivablesCategoryCollectionExcel(
                                      receivablesCategoryList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateReceivablesCategoryCollectionPDF(
                                      receivablesCategoryList,
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
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        height: 250,
                        width: 100,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {
                                    if (event.isInterestedForInteractions &&
                                        pieTouchResponse != null &&
                                        pieTouchResponse.touchedSection !=
                                            null &&
                                        receivablesCategoryList
                                            .categoryData
                                            .isNotEmpty) {
                                      final touchedIndex = pieTouchResponse
                                          .touchedSection!
                                          .touchedSectionIndex;
                                      if (touchedIndex >= 0 &&
                                          touchedIndex <
                                              receivablesCategoryList
                                                  .categoryData
                                                  .length) {
                                        final categoryData =
                                            receivablesCategoryList
                                                .categoryData[touchedIndex];
                                        Tooltip(
                                          triggerMode: TooltipTriggerMode.tap,
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.5,
                                                ),
                                                spreadRadius: 5,
                                                blurRadius: 7,
                                                offset: const Offset(
                                                  0,
                                                  3,
                                                ), // changes position of shadow
                                              ),
                                            ],
                                            color: Colors.white,
                                            borderRadius:
                                                const BorderRadius.all(
                                                  Radius.circular(4),
                                                ),
                                          ),
                                          preferBelow: false,
                                          richMessage: WidgetSpan(
                                            child: Column(
                                              children: [
                                                Text(
                                                  categoryData.categoryName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Column(
                                                  children: [
                                                    Text(
                                                      categoryData
                                                          .categoryAmount
                                                          .toStringAsFixed(2),
                                                    ),
                                                    Text(
                                                      '${categoryData.categoryPercentage.toStringAsFixed(2)} %',
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 1,
                            centerSpaceRadius: 0,
                            startDegreeOffset: 180,
                            sections: _receivablesCategoryChart(),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final categoryData
                                    in receivablesCategoryList.categoryData)
                                  Column(
                                    children: [
                                      Container(
                                        height: 8,
                                        width: 16,
                                        color: getCategoryColor(
                                          categoryData.categoryId,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final categoryData
                                  in receivablesCategoryList.categoryData)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    categoryData.categoryName,
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _receivablesAging() {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: screenWidth,
        child: BarChart(
          BarChartData(
            maxY: getAgingMaxValue(receivablesAgingList),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesReceivableAging,
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
            barGroups: _receivableAgingChartData(
              receivablesAgingList.agingData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedAgingCategory = touchedAgingCategory == ""
                          ? receivablesAgingList
                                .agingData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .agingGroup
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesRep,
                        touchedCustomer,
                        touchedAgingCategory,
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
                    'Overdue Receivables\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            '${receivablesAgingList.agingData[0].agingGroup} :'
                            ' ${(receivablesAgingList.agingData[0].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivablesAgingList.agingData[1].agingGroup} '
                            ': ${(receivablesAgingList.agingData[1].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivablesAgingList.agingData[2].agingGroup} '
                            ': ${(receivablesAgingList.agingData[2].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivablesAgingList.agingData[3].agingGroup} '
                            ': ${(receivablesAgingList.agingData[3].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Total : ${(receivablesAgingList.agingData[3].agingTotal / 100000).toStringAsFixed(2)} L",
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

  Widget _monthlyWiseCollectionAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlyCollectionList.monthlyData.length;
    if (monthlyCollectionList.monthlyData.length > 5) {
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
            maxY: getMaxValue(monthlyCollectionList),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesMonthWiseCollection,
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
            barGroups: _monthWiseCollectionAnalysisChartData(
              monthlyCollectionList.monthlyData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    touchedMonth = monthlyCollectionList
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
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesRep,
                        touchedCustomer,
                        touchedAgingCategory,
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
                    '${monthlyCollectionList.monthlyData[grpIndex].monthName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Achievement : ${(monthlyCollectionList.monthlyData[grpIndex].collectionAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Target : ${(monthlyCollectionList.monthlyData[grpIndex].collectionTarget / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Difference : ${((monthlyCollectionList.monthlyData[grpIndex].collectionAmount - monthlyCollectionList.monthlyData[grpIndex].collectionTarget) / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Percentage : ${((monthlyCollectionList.monthlyData[grpIndex].collectionAmount / monthlyCollectionList.monthlyData[grpIndex].collectionTarget) * 100).toStringAsFixed(2)}%",
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

  Widget _customerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double barChartWidth = 0.0;
    int length = customerWiseCollectionList.customerData.length;
    length > 6
        ? barChartWidth = screenWidth + (30 * length)
        : barChartWidth = screenWidth;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: barChartWidth,
        child: BarChart(
          BarChartData(
            maxY: getCustomerMaxValue(customerWiseCollectionList),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(sideTitles: _bottomTitlesCustomer),
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
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
            barGroups: _customerAnalysisChartData(
              customerWiseCollectionList.customerData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedCustomer = touchedCustomer == ""
                          ? customerWiseCollectionList
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
                        touchedCustomer,
                        touchedAgingCategory,
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
                    '${customerWiseCollectionList.customerData[grpIndex].customerName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Achievement : ${(customerWiseCollectionList.customerData[grpIndex].collectionAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Target : ${(customerWiseCollectionList.customerData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Difference : ${((customerWiseCollectionList.customerData[grpIndex].collectionAmount - customerWiseCollectionList.customerData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Percentage : ${((customerWiseCollectionList.customerData[grpIndex].collectionAmount / customerWiseCollectionList.customerData[grpIndex].targetAmount) * 100).toStringAsFixed(2)}%",
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

  Widget _regionalManagerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = rsmwiseCollectionList.rsmwiseData.length;
    if (rsmwiseCollectionList.rsmwiseData.length > 5) {
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
            maxY: getRsmMaxValue(rsmwiseCollectionList),
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
              rsmwiseCollectionList.rsmwiseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedRegionalManager = touchedRegionalManager == ""
                          ? rsmwiseCollectionList
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
                        touchedCustomer,
                        touchedAgingCategory,
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
                    '${rsmwiseCollectionList.rsmwiseData[grpIndex].rsmName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Achievement : ${(rsmwiseCollectionList.rsmwiseData[grpIndex].collectionAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Target : ${(rsmwiseCollectionList.rsmwiseData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Difference : ${((rsmwiseCollectionList.rsmwiseData[grpIndex].collectionAmount - rsmwiseCollectionList.rsmwiseData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Percentage : ${((rsmwiseCollectionList.rsmwiseData[grpIndex].collectionAmount / rsmwiseCollectionList.rsmwiseData[grpIndex].targetAmount) * 100).ceil().toStringAsFixed(0)}%",
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
    int len = asmwiseCollectionList.asmwiseData.length;
    if (asmwiseCollectionList.asmwiseData.length > 5) {
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
            maxY: getAsmMaxValue(asmwiseCollectionList),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
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
            barGroups: _salesManagerAnalysisChartData(
              asmwiseCollectionList.asmwiseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSalesManager = touchedSalesManager == ""
                          ? asmwiseCollectionList
                                .asmwiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .asmName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesRep,
                        touchedCustomer,
                        touchedAgingCategory,
                      );
                    }
                  });
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
                    '${asmwiseCollectionList.asmwiseData[grpIndex].asmName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Achievement : ${(asmwiseCollectionList.asmwiseData[grpIndex].collectionAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Target : ${(asmwiseCollectionList.asmwiseData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Difference : ${((asmwiseCollectionList.asmwiseData[grpIndex].collectionAmount - asmwiseCollectionList.asmwiseData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Percentage : ${((asmwiseCollectionList.asmwiseData[grpIndex].collectionAmount / asmwiseCollectionList.asmwiseData[grpIndex].targetAmount) * 100).toStringAsFixed(2)}%",
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

  Widget _salesPersonAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = tsmwiseCollectionList.tsmwiseData.length;
    if (tsmwiseCollectionList.tsmwiseData.length > 5) {
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
            maxY: getTsmMaxValue(tsmwiseCollectionList),
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
            barGroups: _salesPersonAnalysisChart(
              tsmwiseCollectionList.tsmwiseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSalesRep = touchedSalesRep == ""
                          ? tsmwiseCollectionList
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
                        touchedCustomer,
                        touchedAgingCategory,
                      );
                    }
                  });
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
                    '${tsmwiseCollectionList.tsmwiseData[grpIndex].tsmName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Achievement : ${(tsmwiseCollectionList.tsmwiseData[grpIndex].collectionAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Target : ${(tsmwiseCollectionList.tsmwiseData[grpIndex].targetAmount / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Difference : ${((tsmwiseCollectionList.tsmwiseData[grpIndex].collectionAmount - tsmwiseCollectionList.tsmwiseData[grpIndex].targetAmount) / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Percentage : ${((tsmwiseCollectionList.tsmwiseData[grpIndex].collectionAmount / tsmwiseCollectionList.tsmwiseData[grpIndex].targetAmount) * 100).toStringAsFixed(2)}%",
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

  void _scrollDown() {
    collectionAnalysisController.animateTo(
      800, //salesPerformancePageController.position.maxScrollExtent
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
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
                        'Filter Options ',
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
