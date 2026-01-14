// ignore_for_file: file_names, use_build_context_synchronously, non_constant_identifier_names, avoid_web_libraries_in_flutter, strict_top_level_inference
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import 'package:optima/login_screen.dart';
import '../../../classes/dashBoard.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:optima/pages/dashboardPages/platform_excel_helper.dart';
import 'package:optima/pages/dashboardPages/platform_pdf_helper.dart';

bool VisitData = false;
bool visitAnalysisDataLoaded = false;
bool touchedLastMonthGoals = false;
bool touchedThisMonthGoals = false;
bool touchedYTDGoals = false;
bool noPromotionData = true;
String UserLevel = "0";
String touchedRegionalManager = "";
String touchedSalesManager = "";
String touchedSalesRep = "";
String touchedCustomer = "";
String touchedProduct = "";
int currentQuarter = 0;
double selectedChart = 0;
double callAvgPerDay = 0;
double callAvgQ1 = 0;
double callAvgQ2 = 0;
double callAvgQ3 = 0;
double callAvgQ4 = 0;
int callAvgQ1Count = 0;
int callAvgQ2Count = 0;
int callAvgQ3Count = 0;
int callAvgQ4Count = 0;
double callAvgPerDayPercent = 0;
double callAvgQ1Percent = 0;
double callAvgQ2Percent = 0;
double callAvgQ3Percent = 0;
double callAvgQ4Percent = 0;
late Future<void> loadDataFuture;
bool chartDataLoaded = false;
DateTime? currentDate;
DateTime? currentMonthFromDate;
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
List<Users> usersListForFilter = [];

class NumberOfVisitsAccData {
  final double visitCount;
  final String accountName;
  NumberOfVisitsAccData({required this.visitCount, required this.accountName});
}

class ProductWisePromotionData {
  final double promotionCount;
  final String productName;
  ProductWisePromotionData({
    required this.promotionCount,
    required this.productName,
  });
}

List<PieChartSectionData> showingSections() {
  return List.generate(2, (i) {
    final isTouched = i == touchedIndex;
    final fontSize = isTouched ? 14.0 : 13.0;
    final radius = isTouched ? 80.0 : 75.0;
    switch (i) {
      case 0:
        return PieChartSectionData(
          color: const Color(0xFFF49136),
          value: double.parse(
            promotionAnalysisList.promotionAnalysisData[i].chartAverage
                .toStringAsFixed(0),
          ),
          title:
              "${promotionAnalysisList.promotionAnalysisData[i].chartAverage.toStringAsFixed(0)} %",
          radius: radius,
          titleStyle: TextStyle(fontSize: fontSize, color: Colors.white),
        );
      case 1:
        return PieChartSectionData(
          color: const Color(0xFF2CA9DF),
          value: double.parse(
            promotionAnalysisList.promotionAnalysisData[i].chartAverage
                .toStringAsFixed(0),
          ),
          title:
              "${promotionAnalysisList.promotionAnalysisData[i].chartAverage.toStringAsFixed(0)} %",
          radius: radius,
          titleStyle: TextStyle(fontSize: fontSize, color: Colors.white),
        );
      default:
        throw Error();
    }
  });
}

int touchedIndex = -1;
DailyVisitSummaryList dailyVisitSummaryList = DailyVisitSummaryList(
  dailyVisitDataSummary: [],
);
DailyVisitList dailyVisitList = DailyVisitList(dailyVisitData: []);
AsmVisitList asmVisitList = AsmVisitList(asmvisitData: []);
TsmVisitList tsmVisitList = TsmVisitList(tsmvisitData: []);
RsmVisitList rsmVisitList = RsmVisitList(rsmvisitData: []);
NumberOfVisitsAccWiseList visitAccountWiseList = NumberOfVisitsAccWiseList(
  visitAccWiseData: [],
);
ProductWisePromotionAnalysisList productPromotionAnalysisList =
    ProductWisePromotionAnalysisList(productWisePromotionData: []);
PromotionAnalysisDataList promotionAnalysisList = PromotionAnalysisDataList(
  promotionAnalysisData: [
    PromotionAnalysisData(chartCaption: "", chartValue: 0, chartAverage: 0),
    PromotionAnalysisData(chartCaption: "", chartValue: 0, chartAverage: 0),
  ],
);
VisitAnalysisList visitAnalysisList = VisitAnalysisList(visitAnalysisData: []);

class VisitAnalysisPage extends StatefulWidget {
  const VisitAnalysisPage({super.key});

  @override
  State<VisitAnalysisPage> createState() => _VisitAnalysisPageState();
}

class _VisitAnalysisPageState extends State<VisitAnalysisPage> {
  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  Widget getBottomTitlesRsm(double val, TitleMeta meta) {
    String text = '';
    RsmVisitData rsmVisitData = rsmVisitList.rsmvisitData.elementAt(
      val.toInt(),
    );
    text = rsmVisitData.rsmName;
    return Text(text.length > 5 ? text.substring(0, 5) : text);
  }

  Widget getBottomTitlesAsm(double val, TitleMeta meta) {
    String text = '';
    AsmVisitData asmVisitData = asmVisitList.asmvisitData.elementAt(
      val.toInt(),
    );
    text = asmVisitData.asmName;
    return Text(text.length > 5 ? text.substring(0, 5) : text);
  }

  Widget getBottomTitlesTsm(double val, TitleMeta meta) {
    String text = '';
    TsmVisitData tsmVisitData = tsmVisitList.tsmvisitData.elementAt(
      val.toInt(),
    );
    text = tsmVisitData.tsmName;
    return Text(text.length > 5 ? text.substring(0, 5) : text);
  }

  Widget getBottomTitlesDailyVisit(double val, TitleMeta meta) {
    String text = '';
    DailyVisitData dailyVisitData = dailyVisitList.dailyVisitData.elementAt(
      val.toInt(),
    );
    text = dailyVisitData.dateName;
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: RotationTransition(
        turns: const AlwaysStoppedAnimation(-25 / 360),
        child: Text(
          text.length > 5 ? text.substring(0, 6) : text,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  SideTitles get _bottomTitlesTsm =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitlesTsm);

  SideTitles get _bottomTitlesAsm =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitlesAsm);

  SideTitles get _bottomTitlesRsm =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitlesRsm);

  SideTitles get _bottomTitlesDailyVisit => SideTitles(
    showTitles: true,
    reservedSize: 35,
    getTitlesWidget: getBottomTitlesDailyVisit,
  );

  SideTitles get _bottomTitlesNumberOfVisitAccountWise => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<NumberOfVisitsAccWiseData> data =
          visitAccountWiseList.visitAccWiseData;
      text = data.elementAt(value.toInt()).accountName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 5
              ? Text(
                  "${text.substring(0, 5)}...",
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesProductWisePromotion => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ProductWisePromotionAnalysisData> data =
          productPromotionAnalysisList.productWisePromotionData;
      text = data.elementAt(value.toInt()).productName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 5
              ? Text(
                  "${text.substring(0, 5)}...",
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  List<BarChartGroupData> _dailyVisitChartData(
    List<DailyVisitData> dailyVisitData,
  ) {
    return dailyVisitData
        .map(
          (daily) => BarChartGroupData(
            x: dailyVisitData.indexOf(daily),
            barRods: [
              BarChartRodData(
                borderRadius: BorderRadius.zero,
                color: const Color(0xFF6CCC3F),
                toY: daily.visitCount.toDouble(),
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _numberOfVisitAccWiseGraphData(
    List<NumberOfVisitsAccWiseData> stageData,
  ) {
    return stageData
        .map(
          (sales) => BarChartGroupData(
            x: stageData.indexOf(sales),
            barRods: [
              BarChartRodData(
                borderRadius: BorderRadius.zero,
                color: const Color(0xFF6CCC3F),
                toY: sales.accountCount.toDouble(),
                width: 20,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _productWisePromotionGraphData(
    List<ProductWisePromotionAnalysisData> stageData,
  ) {
    return stageData
        .map(
          (sales) => BarChartGroupData(
            x: stageData.indexOf(sales),
            barRods: [
              BarChartRodData(
                borderRadius: BorderRadius.zero,
                color: const Color(0xFF6CCC3F),
                toY: sales.productCount.toDouble(),
                width: 20,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _regionalManagerAnalysisChart(
    List<RsmVisitData> rsmVisitData,
  ) {
    return rsmVisitData
        .map(
          (rsm) => BarChartGroupData(
            x: rsmVisitData.indexOf(rsm),
            barRods: [
              BarChartRodData(
                color: const Color.fromARGB(255, 255, 159, 69),
                borderRadius: BorderRadius.zero,
                toY: rsm.visitCount.toDouble(),
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _salesManagerAnalysisChart(
    List<AsmVisitData> asmVisitData,
  ) {
    return asmVisitData
        .map(
          (asm) => BarChartGroupData(
            x: asmVisitData.indexOf(asm),
            barRods: [
              BarChartRodData(
                color: const Color.fromARGB(255, 255, 159, 69),
                borderRadius: BorderRadius.zero,
                toY: asm.visitCount.toDouble(),
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _salesPersonAnalysisChart(
    List<TsmVisitData> tsmVisitData,
  ) {
    return tsmVisitData
        .map(
          (tsm) => BarChartGroupData(
            x: tsmVisitData.indexOf(tsm),
            barRods: [
              BarChartRodData(
                color: const Color.fromARGB(255, 255, 159, 69),
                borderRadius: BorderRadius.zero,
                toY: tsm.visitCount.toDouble(),
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  double getDailyVisitMaxValue(DailyVisitList dailyVisitList) {
    double maxValue = 0;
    for (var soData in dailyVisitList.dailyVisitData) {
      maxValue = maxValue > soData.visitCount
          ? maxValue
          : soData.visitCount.toDouble();
    }
    return ((maxValue ~/ 5) + 1) * 5;
  }

  double getRsmMaxValue(RsmVisitList regionalManagerData) {
    double maxValue = 0;
    for (var soData in regionalManagerData.rsmvisitData) {
      maxValue = maxValue > soData.visitCount
          ? maxValue
          : soData.visitCount.toDouble();
    }
    return ((maxValue ~/ 5) + 1) * 5;
  }

  double getAsmMaxValue(AsmVisitList salesManagerData) {
    double maxValue = 0;
    for (var soData in salesManagerData.asmvisitData) {
      maxValue = maxValue > soData.visitCount
          ? maxValue
          : soData.visitCount.toDouble();
    }
    return ((maxValue ~/ 5) + 1) * 5;
  }

  double getTsmMaxValue(TsmVisitList salesPersonData) {
    double maxValue = 0;
    for (var soData in salesPersonData.tsmvisitData) {
      maxValue = maxValue > soData.visitCount
          ? maxValue
          : soData.visitCount.toDouble();
    }
    return ((maxValue ~/ 5) + 1) * 5;
  }

  int getLastTwoDigitsOfYear(DateTime date) {
    // Get the year from the DateTime object
    int year = date.year;

    // Extract the last two digits of the year using modulo operator
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

  void _clearGraphData() {
    rsmVisitList.rsmvisitData.clear();
    tsmVisitList.tsmvisitData.clear();
    asmVisitList.asmvisitData.clear();
    dailyVisitList.dailyVisitData.clear();
    visitAnalysisList.visitAnalysisData.clear();
  }

  void showLoaderDialogVisit(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> generateVisitAnalysisExcel() async {
    if (visitAnalysisList.visitAnalysisData.isEmpty) {
      visitAnalysisDataLoaded = false;
      await _loadVisitAnalysis(userId, userJwtToken, userMailID);
      if (visitAnalysisList.visitAnalysisData.isEmpty) {
        final snackBar = SnackBar(
          content: Text('Visit Analysis Data loading failed please try again.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      } else {
        setState(() {
          visitAnalysisDataLoaded = true;
        });
      }
    }
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(
      toCellRow([
        'Lead ID',
        'Visit Date',
        'Visit Time',
        'Visit Count',
        'User Name',
        'Account Name',
        'Visit Summary',
        'Visit Type',
        'Product Category',
        'Products',
        'Input Materials',
        'Participants',
        'Check In',
        'In Location',
        'Check Out',
        'Out Location',
      ]),
    );

    for (int column = 0; column <= 15; column++) {
      var cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
      );
      cell.cellStyle = xl.CellStyle(bold: true, fontSize: 14);
    }

    for (var visitData in visitAnalysisList.visitAnalysisData) {
      sheet.appendRow(
        toCellRow([
          visitData.leadID,
          visitData.visitDate,
          visitData.visitTime,
          visitData.visitCount,
          visitData.userName,
          visitData.accountName,
          visitData.leadActivitySummary,
          visitData.visitType,
          visitData.productCategory,
          visitData.productName,
          visitData.leadInputMaterials,
          visitData.participantName,
          visitData.leadActivityCheckin,
          visitData.leadActivityInLocation,
          visitData.leadActivityCheckout,
          visitData.leadActivityLocation,
          //xl.CellStyle(),
        ]),
      );
    }

    xl.CellStyle centerCellStyle = xl.CellStyle(
      verticalAlign: xl.VerticalAlign.Center,
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    int numberOfRows = visitAnalysisList.visitAnalysisData.length;

    for (int rowIndex = 0; rowIndex <= numberOfRows; rowIndex++) {
      for (int colIndex = 0; colIndex <= 15; colIndex++) {
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
      VisitData = true;
    });
    if (kIsWeb) {
      final excelBytes = excel.encode()!;
      saveAndOpenExcel('VisitAnalysis_Report.xlsx', excelBytes);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/VisitAnalysis_Report.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> _loadVisitAnalysis(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'FromDt': fiscalYearStartDate.toString(),
      'ToDt': currentDate.toString(),
      'UserId': userId,
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiHelper.baseUrl}selectvisitanalysisexcel'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode != 200 || json["Status"] != true) {
        final snackBar = SnackBar(content: Text('Error: $json'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }

      final list = (json['Data'] as List)
          .map((e) => VisitAnalysisData.fromJson(e))
          .toList();

      setState(() {
        visitAnalysisList = VisitAnalysisList(visitAnalysisData: list);
        VisitData = list.isNotEmpty;
        visitAnalysisDataLoaded = true;
      });
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadDailyVisitDataSummary(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'FromDt': currentMonthFromDate.toString(),
      'ToDt': currentDate.toString(),
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectnumberofvisitsdaywisesummary';
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
            List<DailyVisitDataSummary> dailyVisitDataSummaryList = [];
            for (var visit in data) {
              DailyVisitDataSummary dailyVisitData = DailyVisitDataSummary(
                visitDate: visit['VisitDate'],
                visitCount: visit['VisitCount'],
                userId: visit['UserId'],
                userName: visit['UserName'],
                userLevel: visit['UserLevel'],
                visitPeriod: visit['VisitPeriod'],
                accountName: visit['AccountName'],
                productName: visit['ProductName'],
                productCount: visit['ProductCount'],
                focusedProducts: visit['FocusedProducts'],
                regularProducts: visit['RegularProducts'],
                focusedAverage: visit['FocusedAverage'],
                regularAverage: visit['RegularAverage'],
              );
              dailyVisitDataSummaryList.add(dailyVisitData);
            }
            setState(() {
              dailyVisitSummaryList = DailyVisitSummaryList(
                dailyVisitDataSummary: dailyVisitDataSummaryList,
              );
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
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadDailyVisitBarChartData(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'FromDt': currentMonthFromDate.toString(),
      'ToDt': currentDate.toString(),
      'UserId': userId,
    };
    callAvgPerDay = 0;
    const apiUrl = '${ApiHelper.baseUrl}selectnumberofvisitsdaywise';
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
            List<DailyVisitData> dailyVisitDataList = [];
            for (var visit in data) {
              DailyVisitData dailyVisitData = DailyVisitData(
                userId: int.tryParse(userId) ?? 0,
                dateName: visit['VisitDate'],
                visitCount: visit['VisitCount'],
                userCount: visit['UserCount'],
              );
              dailyVisitDataList.add(dailyVisitData);
            }
            setState(() {
              dailyVisitList = DailyVisitList(
                dailyVisitData: dailyVisitDataList,
              );
              for (var element in dailyVisitList.dailyVisitData) {
                callAvgPerDay += (element.visitCount / element.userCount);
              }
              callAvgPerDayPercent =
                  callAvgPerDay / dailyVisitList.dailyVisitData.length;
              if (callAvgPerDayPercent > 100) {
                callAvgPerDayPercent = 100;
              }
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
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadEachQtrValues(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    try {
      int i = 1;
      var body = {};
      const apiUrl = '${ApiHelper.baseUrl}selectnumberofvisitsdaywise';
      var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
      callAvgQ1 = 0;
      callAvgQ1Percent = 0;
      callAvgQ2 = 0;
      callAvgQ2Percent = 0;
      callAvgQ3 = 0;
      callAvgQ3Percent = 0;
      callAvgQ4 = 0;
      callAvgQ4Percent = 0;
      for (i; i <= getCurrentQuarter(); i++) {
        switch (i) {
          case 1:
            body = {
              'UserJwtToken': userJwtToken,
              'UsermailID': userMailID,
              'FromDt': q1FromDate.toString(),
              'ToDt': q1ToDate.toString(),
              'UserId': userId,
            };
            break;
          case 2:
            body = {
              'UserJwtToken': userJwtToken,
              'UsermailID': userMailID,
              'FromDt': q2FromDate.toString(),
              'ToDt': q2ToDate.toString(),
              'UserId': userId,
            };
            break;
          case 3:
            body = {
              'UserJwtToken': userJwtToken,
              'UsermailID': userMailID,
              'FromDt': q3FromDate.toString(),
              'ToDt': q3ToDate.toString(),
              'UserId': userId,
            };
            break;
          case 4:
            body = {
              'UserJwtToken': userJwtToken,
              'UsermailID': userMailID,
              'FromDt': q4FromDate.toString(),
              'ToDt': q4ToDate.toString(),
              'UserId': userId,
            };
            break;
          default:
        }
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
              List<DailyVisitData> dailyVisitDataList = [];
              for (var visit in data) {
                DailyVisitData dailyVisitData = DailyVisitData(
                  userId: int.tryParse(userId) ?? 0,
                  dateName: visit['VisitDate'],
                  visitCount: visit['VisitCount'],
                  userCount: visit['UserCount'],
                );
                dailyVisitDataList.add(dailyVisitData);
              }
              setState(() {
                dailyVisitList = DailyVisitList(
                  dailyVisitData: dailyVisitDataList,
                );
                i == 1
                    ? callAvgQ1Count = dailyVisitList.dailyVisitData.length
                    : i == 2
                    ? callAvgQ2Count = dailyVisitList.dailyVisitData.length
                    : i == 3
                    ? callAvgQ3Count = dailyVisitList.dailyVisitData.length
                    : callAvgQ4Count = dailyVisitList.dailyVisitData.length;
                for (var element in dailyVisitList.dailyVisitData) {
                  i == 1
                      ? callAvgQ1 += element.visitCount / element.userCount
                      : i == 2
                      ? callAvgQ2 += element.visitCount / element.userCount
                      : i == 3
                      ? callAvgQ3 += element.visitCount / element.userCount
                      : callAvgQ4 += element.visitCount / element.userCount;
                }
                callAvgQ1Percent = callAvgQ1Count != 0
                    ? callAvgQ1 / callAvgQ1Count
                    : 0;
                callAvgQ2Percent = callAvgQ2Count != 0
                    ? callAvgQ2 / callAvgQ2Count
                    : 0;
                callAvgQ3Percent = callAvgQ3Count != 0
                    ? callAvgQ3 / callAvgQ3Count
                    : 0;
                callAvgQ4Percent = callAvgQ4Count != 0
                    ? callAvgQ4 / callAvgQ4Count
                    : 0;
              });
            }
          } else {
            if (responseJson.containsKey("Error") &&
                responseJson["Error"].toString() ==
                    "Invalid or Expired Token") {
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
        }
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadRSMVisitBarChartData(
    String regionalManager,
    String salesManager,
    String salesRep,
    String accountName,
    String productName,
  ) async {
    try {
      dailyVisitSummaryList = filterVisitList(
        dailyVisitSummaryList,
        usersListForFilter,
        regionalManager: regionalManager,
        salesManager: salesManager,
        salesRep: salesRep,
        accountName: accountName,
        productName: productName,
      );
      List<RsmVisitData> rsmVisitDataList = [];
      Set<String> processedRsmNames = {};
      List<DailyVisitDataSummary> filteredSummaries = dailyVisitSummaryList
          .dailyVisitDataSummary
          .where((element) => element.userLevel == 3)
          .toList();
      String rsmName = "";
      int visitCount = 0, visitPeriod = 0, rsmId = 0;
      for (var visit in filteredSummaries) {
        if (!processedRsmNames.contains(visit.userName)) {
          rsmId = visit.userId;
          rsmName = visit.userName;
          visitPeriod = visit.visitPeriod;
          for (var sales in filteredSummaries.where(
            (sales) => sales.userName == rsmName,
          )) {
            visitCount += sales.visitCount;
          }
          RsmVisitData rsmVisitData = RsmVisitData(
            rsmId: rsmId,
            rsmName: rsmName,
            visitCount: visitCount,
            visitPeriod: visitPeriod,
          );
          rsmVisitDataList.add(rsmVisitData);
        }
        processedRsmNames.add(rsmName);
        visitCount = 0;
        visitPeriod = 0;
        rsmId = 0;
        rsmName = "";
      }
      setState(() {
        chartDataLoaded = true;
        rsmVisitList = RsmVisitList(rsmvisitData: rsmVisitDataList);
      });
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadASMVisitBarChartData(
    String regionalManager,
    String salesManager,
    String salesRep,
    String accountName,
    String productName,
  ) async {
    try {
      dailyVisitSummaryList = filterVisitList(
        dailyVisitSummaryList,
        usersListForFilter,
        regionalManager: regionalManager,
        salesManager: salesManager,
        salesRep: salesRep,
        accountName: accountName,
        productName: productName,
      );
      List<AsmVisitData> asmVisitDataList = [];
      Set<String> processedAsmNames = {};
      List<DailyVisitDataSummary> filteredSummaries = dailyVisitSummaryList
          .dailyVisitDataSummary
          .where((element) => element.userLevel == 2)
          .toList();
      String asmName = "";
      int visitCount = 0, visitPeriod = 0, asmId = 0;
      for (var visit in filteredSummaries) {
        if (!processedAsmNames.contains(visit.userName)) {
          asmId = visit.userId;
          asmName = visit.userName;
          visitPeriod = visit.visitPeriod;
          for (var sales in filteredSummaries.where(
            (sales) => sales.userName == asmName,
          )) {
            visitCount += sales.visitCount;
          }
          AsmVisitData asmVisitData = AsmVisitData(
            asmId: asmId,
            asmName: asmName,
            visitCount: visitCount,
            visitPeriod: visitPeriod,
          );
          asmVisitDataList.add(asmVisitData);
        }
        visitCount = 0;
        visitPeriod = 0;
        asmId = 0;
        asmName = "";
        processedAsmNames.add(asmName);
      }
      setState(() {
        chartDataLoaded = true;
        asmVisitList = AsmVisitList(asmvisitData: asmVisitDataList);
      });
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadTSMVisitBarChartData(
    String regionalManager,
    String salesManager,
    String salesRep,
    String accountName,
    String productName,
  ) async {
    try {
      dailyVisitSummaryList = filterVisitList(
        dailyVisitSummaryList,
        usersListForFilter,
        regionalManager: regionalManager,
        salesManager: salesManager,
        salesRep: salesRep,
        accountName: accountName,
        productName: productName,
      );
      List<TsmVisitData> tsmVisitDataList = [];
      Set<String> processedTsmNames = {};
      List<DailyVisitDataSummary> filteredSummaries = dailyVisitSummaryList
          .dailyVisitDataSummary
          .where((element) => element.userLevel == 1)
          .toList();
      String tsmName = "";
      int visitCount = 0, visitPeriod = 0, tsmId = 0;
      for (var visit in filteredSummaries) {
        if (!processedTsmNames.contains(visit.userName)) {
          tsmId = visit.userId;
          tsmName = visit.userName;
          visitPeriod = visit.visitPeriod;
          for (var sales in filteredSummaries.where(
            (sales) => sales.userName == tsmName,
          )) {
            visitCount += sales.visitCount;
          }
          TsmVisitData tsmVisitData = TsmVisitData(
            tsmId: tsmId,
            tsmName: tsmName,
            visitCount: visitCount,
            visitPeriod: visitPeriod,
          );
          tsmVisitDataList.add(tsmVisitData);
        }
        processedTsmNames.add(tsmName);
        visitCount = 0;
        visitPeriod = 0;
        tsmId = 0;
        tsmName = "";
      }
      setState(() {
        chartDataLoaded = true;
        tsmVisitList = TsmVisitList(tsmvisitData: tsmVisitDataList);
      });
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadNumberOfVisitsAccWise(
    String regionalManager,
    String salesManager,
    String salesRep,
    String accountName,
    String productName,
  ) async {
    try {
      dailyVisitSummaryList = filterVisitList(
        dailyVisitSummaryList,
        usersListForFilter,
        regionalManager: regionalManager,
        salesManager: salesManager,
        salesRep: salesRep,
        accountName: accountName,
        productName: productName,
      );
      List<NumberOfVisitsAccWiseData> visitsAccWiseData = [];
      List<DailyVisitDataSummary> filteredSummaries = dailyVisitSummaryList
          .dailyVisitDataSummary
          .toList();
      String customerName = "";
      int visitCount = 0;
      for (var visit in filteredSummaries) {
        customerName = visit.accountName;
        for (var acc in filteredSummaries.where(
          (acc) => acc.accountName == customerName,
        )) {
          visitCount += acc.visitCount;
        }
        NumberOfVisitsAccWiseData visitData = NumberOfVisitsAccWiseData(
          accountName: customerName,
          accountCount: visitCount,
        );
        visitsAccWiseData.add(visitData);
        visitCount = 0;
        customerName = "";
      }
      setState(() {
        chartDataLoaded = true;
        visitAccountWiseList = NumberOfVisitsAccWiseList(
          visitAccWiseData: visitsAccWiseData,
        );
      });
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadPromotionAnalysis(
    String regionalManager,
    String salesManager,
    String salesRep,
    String accountName,
    String productName,
  ) async {
    try {
      dailyVisitSummaryList = filterVisitList(
        dailyVisitSummaryList,
        usersListForFilter,
        regionalManager: regionalManager,
        salesManager: salesManager,
        salesRep: salesRep,
        accountName: accountName,
        productName: productName,
      );
      List<PromotionAnalysisData> promotionData = [];

      List<DailyVisitDataSummary> filteredSummaries = dailyVisitSummaryList
          .dailyVisitDataSummary
          .toList();
      int promotionCount = 0,
          regularCount = 0,
          focusedAverage = 0,
          regularAverage = 0;

      for (var visit in filteredSummaries) {
        promotionCount += visit.focusedProducts;
        regularCount += visit.regularProducts;

        focusedAverage = visit.focusedAverage;
        regularAverage = visit.regularAverage;
      }
      PromotionAnalysisData visitData = PromotionAnalysisData(
        chartCaption: 'Focused Products',
        chartValue: promotionCount,
        chartAverage: focusedAverage,
      );
      promotionData.add(visitData);
      visitData = PromotionAnalysisData(
        chartCaption: 'Regular Products',
        chartValue: regularCount,
        chartAverage: regularAverage,
      );
      promotionData.add(visitData);

      setState(() {
        if (promotionData[0].chartAverage == 0 &&
            promotionData[1].chartAverage == 0) {
          noPromotionData = false;
        }
        promotionAnalysisList.promotionAnalysisData.clear();
        promotionAnalysisList = PromotionAnalysisDataList(
          promotionAnalysisData: promotionData,
        );
      });
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadProductWisePromotionAnalysis(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'FromDt': currentMonthFromDate.toString(),
      'ToDt': addMonth(
        currentMonthFromDate!,
        1,
      ).add(const Duration(days: -1)).toString(),
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectproductwisechart';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        // bool status = responseJson["Status"];
        if (responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'] ?? [];
          if (data.isNotEmpty) {
            List<ProductWisePromotionAnalysisData> productPromotionData = [];
            for (var visit in data) {
              ProductWisePromotionAnalysisData visitData =
                  ProductWisePromotionAnalysisData(
                    productName: visit['ProductName'] ?? "",
                    productCount: visit['ProductCount'] ?? 0,
                  );
              productPromotionData.add(visitData);
            }
            setState(() {
              chartDataLoaded = true;
              productPromotionAnalysisList = ProductWisePromotionAnalysisList(
                productWisePromotionData: productPromotionData,
              );
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
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
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

  Future<void> loadDataWithFilter(
    String regionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String productCode,
  ) async {
    LoadDates();
    LoadAllQuarterFromToDates();

    UserLevel = userLevel;
    await _loadUserListForFilter(
      userId,
      userJwtToken,
      userMailID,
      int.tryParse(userLevel) ?? 0,
    );
    await _loadDailyVisitDataSummary(userId, userJwtToken, userMailID);
    await _loadDailyVisitBarChartData(userId, userJwtToken, userMailID);
    await _loadNumberOfVisitsAccWise(
      regionalManager,
      salesManager,
      salesRep,
      customerCode,
      productCode,
    );
    await _loadPromotionAnalysis(
      regionalManager,
      salesManager,
      salesRep,
      customerCode,
      productCode,
    );
    if (UserLevel != "1") {
      await _loadRSMVisitBarChartData(
        regionalManager,
        salesManager,
        salesRep,
        customerCode,
        productCode,
      );
      await _loadASMVisitBarChartData(
        regionalManager,
        salesManager,
        salesRep,
        customerCode,
        productCode,
      );
      await _loadTSMVisitBarChartData(
        regionalManager,
        salesManager,
        salesRep,
        customerCode,
        productCode,
      );
    }
    await _loadProductWisePromotionAnalysis(userId, userJwtToken, userMailID);
    chartDataLoaded = true;
  }

  Future<void> loadData(String selectedUser) async {
    await _loadUserSession();
    UserLevel = userLevel;
    await _loadUserListForFilter(
      userId,
      userJwtToken,
      userMailID,
      int.tryParse(userLevel) ?? 0,
    );
    await _loadDailyVisitDataSummary(userId, userJwtToken, userMailID);
    await _loadEachQtrValues(userId, userJwtToken, userMailID);
    await _loadDailyVisitBarChartData(userId, userJwtToken, userMailID);
    await _loadNumberOfVisitsAccWise("", "", "", "", "");
    await _loadPromotionAnalysis("", "", "", "", "");
    if (int.tryParse(UserLevel)! >= 3) {
      await _loadRSMVisitBarChartData("", "", "", "", "");
      await _loadASMVisitBarChartData("", "", "", "", "");
      await _loadTSMVisitBarChartData("", "", "", "", "");
    } else if (int.tryParse(UserLevel)! <= 2) {
      await _loadASMVisitBarChartData("", "", "", "", "");
      await _loadTSMVisitBarChartData("", "", "", "", "");
    } else if (int.tryParse(UserLevel)! == 1) {
      await _loadTSMVisitBarChartData("", "", "", "", "");
    }
    await _loadProductWisePromotionAnalysis(userId, userJwtToken, userMailID);
    chartDataLoaded = true;
  }

  Future<void> loadDataNew(String selectedUser) async {
    await _loadUserSession();

    await Future.wait([
      _loadUserListForFilter(
        userId,
        userJwtToken,
        userMailID,
        int.tryParse(userLevel) ?? 0,
      ),
      _loadDailyVisitDataSummary(userId, userJwtToken, userMailID),
      _loadEachQtrValues(userId, userJwtToken, userMailID),
      _loadDailyVisitBarChartData(userId, userJwtToken, userMailID),
      _loadNumberOfVisitsAccWise("", "", "", "", ""),
      _loadPromotionAnalysis("", "", "", "", ""),
      _loadProductWisePromotionAnalysis(userId, userJwtToken, userMailID),
    ]);

    if (int.parse(userLevel) <= 3) {
      await Future.wait([
        _loadRSMVisitBarChartData("", "", "", "", ""),
        _loadASMVisitBarChartData("", "", "", "", ""),
        _loadTSMVisitBarChartData("", "", "", "", ""),
      ]);
    }

    setState(() => chartDataLoaded = true);
  }

  Future<void> removeFilter() async {
    touchedRegionalManager = "";
    touchedSalesManager = "";
    touchedSalesRep = "";
    touchedCustomer = "";
    touchedProduct = "";
    LoadDates();
    LoadAllQuarterFromToDates();
    _clearGraphData();

    UserLevel = userLevel;
    await _loadUserListForFilter(
      userId,
      userJwtToken,
      userMailID,
      int.tryParse(userLevel) ?? 0,
    );
    await _loadDailyVisitDataSummary(userId, userJwtToken, userMailID);
    await _loadDailyVisitBarChartData(userId, userJwtToken, userMailID);
    await _loadNumberOfVisitsAccWise("", "", "", "", "");
    await _loadPromotionAnalysis("", "", "", "", "");
    if (int.tryParse(UserLevel)! <= 3) {
      await _loadRSMVisitBarChartData("", "", "", "", "");
      await _loadASMVisitBarChartData("", "", "", "", "");
      await _loadTSMVisitBarChartData("", "", "", "", "");
    }
    await _loadProductWisePromotionAnalysis(userId, userJwtToken, userMailID);
    chartDataLoaded = true;
  }

  DailyVisitSummaryList filterVisitList(
    DailyVisitSummaryList visitList,
    List<Users> userNames, {
    String? regionalManager,
    String? salesManager,
    String? salesRep,
    String? accountName,
    String? productName,
  }) {
    bool regionalManagerCondition = true;
    bool salesManagerCondition = true;
    DailyVisitSummaryList filteredVisitList = DailyVisitSummaryList(
      dailyVisitDataSummary: [],
    );

    for (var visit in visitList.dailyVisitDataSummary) {
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
            childMenuNames.contains(visit.userName);
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
            salesManagerMenuId != -1 && childMenuNames.contains(visit.userName);
      }
      if (!regionalManagerCondition || !salesManagerCondition) {
        continue; // Skip this sale if either regionalManager or salesManager condition fails
      }
      if ((salesRep == null ||
              salesRep.isEmpty ||
              visit.userName == salesRep) &&
          (accountName == null ||
              accountName.isEmpty ||
              visit.accountName == accountName) &&
          (productName == null ||
              productName.isEmpty ||
              visit.productName == productName)) {
        filteredVisitList.dailyVisitDataSummary.add(visit);
      }
    }
    return filteredVisitList;
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> generateDailyNumberVisitExcel(DailyVisitList data) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Date', 'Visit Count']));
      for (var itemData in data.dailyVisitData) {
        sheet.appendRow(toCellRow([itemData.dateName, itemData.visitCount]));
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'daily_number_of_visits.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('daily_number_of_visits.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/daily_number_of_visits.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateDailyNumberVisitPDF(DailyVisitList data) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Daily Number of Visits',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );
      for (var data in data.dailyVisitData) {
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Date : ${data.dateName}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    'Visit Count: ${data.visitCount}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(height: 20), // Add space between entries
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

  Future<void> generateRegionalManagerVisitExcel(RsmVisitList data) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Name', 'Visit Count', 'Call Avg.']));
      for (var itemData in data.rsmvisitData) {
        sheet.appendRow(
          toCellRow([
            itemData.rsmName,
            itemData.visitCount,
            (itemData.visitCount / itemData.visitPeriod).toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'regional_managers_visit.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('regional_managers_visit.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/regional_managers_visit.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateRegionalManagerVisitPDF(RsmVisitList data) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                "Regional Manager's Visit ",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );
      for (var data in data.rsmvisitData) {
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Name : ${data.rsmName}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    'Visit Count: ${data.visitCount}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    'Call Avg.: ${(data.visitCount / data.visitPeriod).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),

                  pw.SizedBox(height: 20), // Add space between entries
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
        final file = File('$storageDir/regional_managers_visit.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesManagerVisitExcel(AsmVisitList data) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Name', 'Visit Count', 'Call Avg.']));
      for (var itemData in data.asmvisitData) {
        sheet.appendRow(
          toCellRow([
            itemData.asmName,
            itemData.visitCount,
            (itemData.visitCount / itemData.visitPeriod).toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'sales_managers_visit.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('sales_managers_visit.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/sales_managers_visit.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesManagerVisitPDF(AsmVisitList data) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                "Sales Manager's Visit ",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );
      for (var data in data.asmvisitData) {
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Name : ${data.asmName}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    'Visit Count: ${data.visitCount}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    'Call Avg.: ${(data.visitCount / data.visitPeriod).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),

                  pw.SizedBox(height: 20), // Add space between entries
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
        final file = File('$storageDir/sales_managers_visit.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesPersonVisitExcel(TsmVisitList data) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Name', 'Visit Count', 'Call Avg.']));
      for (var itemData in data.tsmvisitData) {
        sheet.appendRow(
          toCellRow([
            itemData.tsmName,
            itemData.visitCount,
            (itemData.visitCount / itemData.visitPeriod).toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'sales_person_visit.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('sales_person_visit.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/sales_person_visit.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesPersonVisitPDF(TsmVisitList data) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                "Sales Person's Visit ",
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
      final totalPages = (data.tsmvisitData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > data.tsmvisitData.length
            ? data.tsmvisitData.length
            : start + rowsPerPage;
        final tableData = data.tsmvisitData.sublist(start, end);

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
                        'Visit Count',
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
                          monthlyData.visitCount.toString(),
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
        final file = File('$storageDir/sales_persons_visit.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateNumberOfVisitsAccWiseExcel(
    NumberOfVisitsAccWiseList data,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Account Name', 'Visit Count']));
      for (var itemData in data.visitAccWiseData) {
        sheet.appendRow(
          toCellRow([itemData.accountName, itemData.accountCount]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'number_of_visits_acc_wise.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('number_of_visits_acc_wise.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/number_of_visits_acc_wise.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateNumberOfVisitsAccWisePDF(
    NumberOfVisitsAccWiseList data,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Number of Visits Accounts Wise',
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
      final totalPages = (data.visitAccWiseData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > data.visitAccWiseData.length
            ? data.visitAccWiseData.length
            : start + rowsPerPage;
        final tableData = data.visitAccWiseData.sublist(start, end);

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
                        'Visit Count',
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
                          monthlyData.accountName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.accountCount.toString(),
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

  Future<void> generatePromotionAnalysisExcel(
    PromotionAnalysisDataList data,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Type of Product', 'Percentage']));
      for (var itemData in data.promotionAnalysisData) {
        sheet.appendRow(
          toCellRow([itemData.chartCaption, itemData.chartAverage]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'promotion_analysis.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('promotion_analysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/promotion_analysis.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generatePromotionAnalysisPDF(
    PromotionAnalysisDataList data,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Promotion Analysis',
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
      final totalPages = (data.promotionAnalysisData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > data.promotionAnalysisData.length
            ? data.promotionAnalysisData.length
            : start + rowsPerPage;
        final tableData = data.promotionAnalysisData.sublist(start, end);

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
                        'Visit Count',
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
                          monthlyData.chartCaption,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.chartAverage
                              .toStringAsFixed(2)
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
        final file = File('$storageDir/receivables_aging.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateProductWisePromotionAnalysisExcel(
    ProductWisePromotionAnalysisList data,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Product Name', 'Count']));
      for (var itemData in data.productWisePromotionData) {
        sheet.appendRow(
          toCellRow([itemData.productName, itemData.productCount]),
        );
      }
      if (kIsWeb) {
        // var fileBytes = excel.encode();
        // final blob = html.Blob([fileBytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..download = 'product_wise_promotion_analysis.xlsx'
        //   ..style.display = 'none';
        // html.document.body!.append(anchor);
        // anchor.click();
        // anchor.remove();
        // html.Url.revokeObjectUrl(url);
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('product_wise_promotion_analysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/product_wise_promotion_analysis.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateProductWisePromotionAnalysisPDF(
    ProductWisePromotionAnalysisList data,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Product Wise Promotion Analysis',
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
      final totalPages = (data.productWisePromotionData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > data.productWisePromotionData.length
            ? data.productWisePromotionData.length
            : start + rowsPerPage;
        final tableData = data.productWisePromotionData.sublist(start, end);

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
                        'Product Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Count',
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
                          monthlyData.productName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.productCount.toString(),
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
        final file = File('$storageDir/product_wise_promotion_analysis.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
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

  late String userId, userJwtToken, userMailID, userLevel;

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    userJwtToken = prefs.getString('userJwtToken') ?? '';
    userMailID = prefs.getString('userMailID') ?? '';
    userLevel = prefs.getString('userLevel') ?? '0';
  }

  @override
  void initState() {
    super.initState();
    callAvgPerDayPercent = 0;
    VisitData = false;
    visitAnalysisDataLoaded = false;

    LoadDates();
    LoadAllQuarterFromToDates();
    _clearGraphData();

    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  void dispose() {
    chartDataLoaded = false;
    tsmVisitList.tsmvisitData.clear();
    asmVisitList.asmvisitData.clear();
    dailyVisitList.dailyVisitData.clear();
    callAvgPerDay = 0;
    callAvgQ1 = 0;
    callAvgQ2 = 0;
    callAvgQ3 = 0;
    callAvgQ4 = 0;
    callAvgPerDayPercent = 0;
    callAvgQ1Percent = 0;
    callAvgQ2Percent = 0;
    callAvgQ3Percent = 0;
    callAvgQ4Percent = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formattedDateFirstOfThisMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month, 1));
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
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
                        Text(
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
                        PopupMenuButton(
                          onSelected: (value) async {
                            if (value == 'excel') {
                              showLoaderDialogVisit(context);

                              await generateVisitAnalysisExcel();

                              if (mounted) {
                                Navigator.pop(context); // close loader
                              }
                            }
                          },
                          itemBuilder: (BuildContext bc) {
                            return [
                              const PopupMenuItem(
                                value: 'excel',
                                child: Row(children: [Text("Download Excel")]),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                right: 4.0,
                              ),
                              child: CircularPercentIndicator(
                                arcType: ArcType.HALF,
                                radius: 55.0,
                                lineWidth: 20.0,
                                animation: true,
                                percent: callAvgPerDayPercent / 100,
                                center: Column(
                                  children: [
                                    const SizedBox(height: 30),
                                    Text(
                                      callAvgPerDayPercent.toStringAsFixed(2),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: touchedLastMonthGoals
                                            ? 13.0
                                            : 12.0,
                                        color: touchedLastMonthGoals
                                            ? Colors.cyan
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Center(
                                      child: Text(
                                        "Call Avg/Day",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: touchedLastMonthGoals
                                              ? 11.0
                                              : 10.0,
                                          color: touchedLastMonthGoals
                                              ? Colors.cyan
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                curve: Curves.linear,
                                circularStrokeCap: CircularStrokeCap.butt,
                                progressColor: const Color(0xFF6CCC3F),
                                arcBackgroundColor: Colors.grey.shade200,
                              ),
                            ),
                            const SizedBox(width: 30),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: CircularPercentIndicator(
                                arcType: ArcType.HALF,
                                radius: 55.0,
                                lineWidth: 20.0,
                                animation: true,
                                percent: 0.0,
                                center: Column(
                                  children: [
                                    const SizedBox(height: 70),
                                    Center(
                                      child: Text(
                                        "Coverage",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: touchedLastMonthGoals
                                              ? 11.0
                                              : 10.0,
                                          color: touchedLastMonthGoals
                                              ? Colors.cyan
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                curve: Curves.linear,
                                circularStrokeCap: CircularStrokeCap.butt,
                                progressColor: const Color(0xFF2CA9DF),
                                arcBackgroundColor: Colors.grey.shade200,
                              ),
                            ),
                          ],
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
                      Row(
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
                              child: callAvgQ1Percent.toStringAsFixed(2) != ""
                                  ? Text(callAvgQ1Percent.toStringAsFixed(2))
                                  : const Text("      "),
                            ),
                          ),
                        ],
                      ),
                      Row(
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
                              child: callAvgQ2Percent.toStringAsFixed(2) != ""
                                  ? Text(callAvgQ2Percent.toStringAsFixed(2))
                                  : const Text("      "),
                            ),
                          ),
                        ],
                      ),
                      Row(
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
                              child: callAvgQ3Percent.toStringAsFixed(2) != ""
                                  ? Text(callAvgQ3Percent.toStringAsFixed(2))
                                  : const Text("      "),
                            ),
                          ),
                        ],
                      ),
                      Row(
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
                              child: callAvgQ4Percent.toStringAsFixed(2) != ""
                                  ? Text(callAvgQ4Percent.toStringAsFixed(2))
                                  : const Text("      "),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                  child: Divider(thickness: 2),
                ),
                Visibility(
                  visible: dailyVisitList.dailyVisitData.isNotEmpty,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 15),
                          Text(
                            "Daily Number of Visits",
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
                                      generateDailyNumberVisitExcel(
                                        dailyVisitList,
                                      );
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateDailyNumberVisitPDF(
                                        dailyVisitList,
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: dailyVisitList.dailyVisitData.isEmpty
                      ? const SizedBox.shrink()
                      : _dailyVisitGraph(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: dailyVisitList.dailyVisitData.isEmpty
                      ? const SizedBox.shrink()
                      : const Divider(thickness: 2),
                ),
                Visibility(
                  visible: rsmVisitList.rsmvisitData.isNotEmpty,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 15),
                          Text(
                            "Regional Manager's Visits",
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
                                      generateRegionalManagerVisitExcel(
                                        rsmVisitList,
                                      );
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateRegionalManagerVisitPDF(
                                        rsmVisitList,
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: rsmVisitList.rsmvisitData.isEmpty
                      ? const SizedBox.shrink()
                      : _regionalManagerAnalysis(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: rsmVisitList.rsmvisitData.isEmpty
                      ? const SizedBox.shrink()
                      : const Divider(thickness: 2),
                ),
                Visibility(
                  visible: asmVisitList.asmvisitData.isNotEmpty,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 15),
                          Text(
                            "Sales Manager's Visits",
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
                                      generateSalesManagerVisitExcel(
                                        asmVisitList,
                                      );
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateSalesManagerVisitPDF(
                                        asmVisitList,
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: asmVisitList.asmvisitData.isEmpty
                      ? const SizedBox.shrink()
                      : _salesManagerAnalysis(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: asmVisitList.asmvisitData.isEmpty
                      ? const SizedBox.shrink()
                      : const Divider(thickness: 2),
                ),
                Visibility(
                  visible: tsmVisitList.tsmvisitData.isNotEmpty,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 15),
                          Text(
                            "Sales Person's Visits",
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
                                      generateSalesPersonVisitExcel(
                                        tsmVisitList,
                                      );
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateSalesPersonVisitPDF(tsmVisitList);
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
                ),
                Visibility(
                  visible: tsmVisitList.tsmvisitData.isNotEmpty,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: tsmVisitList.tsmvisitData.isEmpty
                            ? const SizedBox.shrink()
                            : _salesPersonAnalysis(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 16.0,
                        ),
                        child: Divider(thickness: 2),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: asmVisitList.asmvisitData.isEmpty
                      ? const SizedBox.shrink()
                      : const Divider(thickness: 2),
                ),
                Visibility(
                  visible: visitAccountWiseList.visitAccWiseData.isNotEmpty,
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
                                "Number of Visits Account Wise",
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
                                          generateNumberOfVisitsAccWiseExcel(
                                            visitAccountWiseList,
                                          );
                                        });
                                      },
                                      child: const Text("Download Excel"),
                                    ),
                                    PopupMenuItem(
                                      onTap: () {
                                        setState(() {
                                          generateNumberOfVisitsAccWisePDF(
                                            visitAccountWiseList,
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
                        child: _numberOfVisitsAccountWiseGraph(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Divider(thickness: 2),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: noPromotionData,
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
                                "Promotion Analysis",
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
                                          generatePromotionAnalysisExcel(
                                            promotionAnalysisList,
                                          );
                                        });
                                      },
                                      child: const Text("Download Excel"),
                                    ),
                                    PopupMenuItem(
                                      onTap: () {
                                        setState(() {
                                          generatePromotionAnalysisPDF(
                                            promotionAnalysisList,
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
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 0.0,
                                    right: 24,
                                  ),
                                  child: SizedBox(
                                    height: 100,
                                    width: 100,
                                    child: PieChart(
                                      PieChartData(
                                        pieTouchData: PieTouchData(
                                          touchCallback:
                                              (
                                                FlTouchEvent event,
                                                pieTouchResponse,
                                              ) {
                                                setState(() {
                                                  if (!event
                                                          .isInterestedForInteractions ||
                                                      pieTouchResponse ==
                                                          null ||
                                                      pieTouchResponse
                                                              .touchedSection ==
                                                          null) {
                                                    touchedIndex = -1;
                                                    return;
                                                  }
                                                  touchedIndex =
                                                      pieTouchResponse
                                                          .touchedSection!
                                                          .touchedSectionIndex;
                                                });
                                              },
                                        ),
                                        borderData: FlBorderData(show: false),
                                        sectionsSpace: 0,
                                        centerSpaceRadius: 0,
                                        startDegreeOffset: 180,
                                        sections: showingSections(),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 8,
                                            width: 16,
                                            color: const Color(0xFFF49136),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            height: 8,
                                            width: 16,
                                            color: const Color(0xFF2CA9DF),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(
                                            "Focused Products",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(
                                            "Regular Products",
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Divider(thickness: 2),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: productPromotionAnalysisList
                      .productWisePromotionData
                      .isNotEmpty,
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
                                "Product Wise Promotion Analysis",
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
                                          generateProductWisePromotionAnalysisExcel(
                                            productPromotionAnalysisList,
                                          );
                                        });
                                      },
                                      child: const Text("Download Excel"),
                                    ),
                                    PopupMenuItem(
                                      onTap: () {
                                        setState(() {
                                          generateProductWisePromotionAnalysisPDF(
                                            productPromotionAnalysisList,
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
                        child: _productWisePromotionAnalysisGraph(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _dailyVisitGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = dailyVisitList.dailyVisitData.length;
    if (dailyVisitList.dailyVisitData.length > 5) {
      chartWidth = screenWidth + (10 * len);
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
            maxY: getDailyVisitMaxValue(dailyVisitList),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesDailyVisit,
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
            barGroups: _dailyVisitChartData(dailyVisitList.dailyVisitData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {});
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
                    '${dailyVisitList.dailyVisitData[grpIndex].dateName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'No. of visit : ${(dailyVisitList.dailyVisitData[grpIndex].visitCount).toStringAsFixed(0)}\n',
                        style: const TextStyle(
                          color: Colors.black,
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
    int len = rsmVisitList.rsmvisitData.length;
    if (rsmVisitList.rsmvisitData.length > 5) {
      chartWidth = screenWidth + (40 * len);
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
            maxY: getRsmMaxValue(rsmVisitList),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
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
            barGroups: _regionalManagerAnalysisChart(rsmVisitList.rsmvisitData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedRegionalManager = touchedRegionalManager == ""
                          ? rsmVisitList
                                .rsmvisitData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .rsmName
                                .toString()
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      loadDataWithFilter(
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesRep,
                        touchedCustomer,
                        touchedProduct,
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
                    '${rsmVisitList.rsmvisitData[grpIndex].rsmName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'No. of visit : ${(rsmVisitList.rsmvisitData[grpIndex].visitCount).toStringAsFixed(0)}\n',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Call Avg. : ${(rsmVisitList.rsmvisitData[grpIndex].visitCount / rsmVisitList.rsmvisitData[grpIndex].visitPeriod).toStringAsFixed(2)}\n',
                        style: const TextStyle(
                          color: Colors.black,
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
    int len = asmVisitList.asmvisitData.length;
    if (asmVisitList.asmvisitData.length > 5) {
      chartWidth = screenWidth + (40 * len);
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
            maxY: getAsmMaxValue(asmVisitList),
            titlesData: FlTitlesData(
              show: true,
              // leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
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
            barGroups: _salesManagerAnalysisChart(asmVisitList.asmvisitData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSalesManager = touchedSalesManager == ""
                          ? asmVisitList
                                .asmvisitData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .asmName
                                .toString()
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      loadDataWithFilter(
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesRep,
                        touchedCustomer,
                        touchedProduct,
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
                    '${asmVisitList.asmvisitData[grpIndex].asmName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'No. of visit : ${(asmVisitList.asmvisitData[grpIndex].visitCount).toStringAsFixed(0)}\n',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Call Avg. : ${(asmVisitList.asmvisitData[grpIndex].visitCount / asmVisitList.asmvisitData[grpIndex].visitPeriod).toStringAsFixed(2)}\n',
                        style: const TextStyle(
                          color: Colors.black,
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
    int len = tsmVisitList.tsmvisitData.length;
    if (tsmVisitList.tsmvisitData.length > 5) {
      chartWidth = screenWidth + (40 * len);
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
            maxY: getTsmMaxValue(tsmVisitList),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
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
            barGroups: _salesPersonAnalysisChart(tsmVisitList.tsmvisitData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSalesRep = touchedSalesRep == ""
                          ? tsmVisitList
                                .tsmvisitData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .tsmName
                                .toString()
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      loadDataWithFilter(
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesRep,
                        touchedCustomer,
                        touchedProduct,
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
                    '${tsmVisitList.tsmvisitData[grpIndex].tsmName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'No. of visit : ${(tsmVisitList.tsmvisitData[grpIndex].visitCount).toStringAsFixed(0)}\n',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Call Avg. : ${(tsmVisitList.tsmvisitData[grpIndex].visitCount / tsmVisitList.tsmvisitData[grpIndex].visitPeriod).toStringAsFixed(2)}\n',
                        style: const TextStyle(
                          color: Colors.black,
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

  Widget _numberOfVisitsAccountWiseGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = visitAccountWiseList.visitAccWiseData.length;
    if (visitAccountWiseList.visitAccWiseData.length > 5) {
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
            // maxY: getMaxValue(monthlySalesList),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesNumberOfVisitAccountWise,
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
            barGroups: _numberOfVisitAccWiseGraphData(
              visitAccountWiseList.visitAccWiseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedCustomer = touchedCustomer == ""
                          ? visitAccountWiseList
                                .visitAccWiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .accountName
                                .toString()
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      loadDataWithFilter(
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesRep,
                        touchedCustomer,
                        touchedProduct,
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
                    '',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            '${visitAccountWiseList.visitAccWiseData[grpIndex].accountName}\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text:
                            "No. of Visits : ${visitAccountWiseList.visitAccWiseData[grpIndex].accountCount}",
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

  Widget _productWisePromotionAnalysisGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = productPromotionAnalysisList.productWisePromotionData.length;
    if (productPromotionAnalysisList.productWisePromotionData.length > 5) {
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
            // maxY: getMaxValue(monthlySalesList),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesProductWisePromotion,
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
            barGroups: _productWisePromotionGraphData(
              productPromotionAnalysisList.productWisePromotionData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchTooltipData: BarTouchTooltipData(
                maxContentWidth: 200,
                tooltipBorder: const BorderSide(
                  width: 2.0,
                  color: Colors.black12,
                  style: BorderStyle.none,
                ),
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            '${productPromotionAnalysisList.productWisePromotionData[grpIndex].productName}\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Count: ${productPromotionAnalysisList.productWisePromotionData[grpIndex].productCount}",
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
}
