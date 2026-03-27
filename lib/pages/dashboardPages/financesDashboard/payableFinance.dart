// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/login_screen.dart';
import '../../../classes/dashBoard.dart';
import '../../../classes/dataManager.dart';
import '../../../classes/leads.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import '../platform_excel_helper.dart';
import '../platform_pdf_helper.dart';

class PayableFinance extends StatefulWidget {
  const PayableFinance({super.key});

  @override
  State<PayableFinance> createState() => _PayableFinanceState();
}

late Future<void> loadDataFuture;
List<Users> usersList = [];
List<Users> childUsers = [];
List<Map<String, dynamic>> userList = [];
bool noUserList = false;
String UserLevel = "0";
List<PayablesList> payablesList = [];
List<PayablesList> payablesListMaster = [];
List<ModeOfPaymentList> modeOfPayment = [];
List<SalesTargetList> salesTarget = [];
bool chartDataLoadedPayables = false;

double payableDouble = 0.0;
String payableStr = "";
double advanceDouble = 0.0;
String advanceStr = "";
String payableAdvanceStr = "";
int payableAdvancePercentage = 0;

double notDue = 0;
double overDue = 0;
double netPayable = 0;
int netPayablePercentage = 0;
String netPayableStr = "";
String overDueStr = "";
String notDueStr = "";

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

PayablesGraphList payableGraphList = PayablesGraphList(agingData: []);
AdvancePaidToSupplierPayablesList receivableList =
    AdvancePaidToSupplierPayablesList(agingData: []);
SupplierAnalysisPayablesList supplierList = SupplierAnalysisPayablesList(
  supplierData: [],
);
SupplierAnalysisPayablesList advanceVendorList = SupplierAnalysisPayablesList(
  supplierData: [],
);
VendorsPaymentProjectionList vendorProjectionList =
    VendorsPaymentProjectionList(vendorData: []);
VendorsPaymentProjectionList capitalVendorsList = VendorsPaymentProjectionList(
  vendorData: [],
);
SupplierCategoryWiseAnalysisPayablesList supplierCategoryList =
    SupplierCategoryWiseAnalysisPayablesList(supplierCategoryData: []);
SupplierCategoryWiseAnalysisPayablesList bpGroupList =
    SupplierCategoryWiseAnalysisPayablesList(supplierCategoryData: []);
SupplierCategoryWiseAnalysisPayablesList fixedExpensesList =
    SupplierCategoryWiseAnalysisPayablesList(supplierCategoryData: []);
DocumentTypeList documentList = DocumentTypeList(documentData: []);

String touchedPayables = "";
String touchedAdvancePaid = "";
String touchedSupplier = "";
String touchedSupplierType = "";
String touchedDocumentType = "";
String touchedBPgroup = "";
double selectedChart = 0;

List<String> selectedSalesData = [];

final List<String> categories = ['Category', 'Supplier', 'Date'];

List<List<String>> filterOptions = [listOfCategory, listOfSupplier, []];

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

List<PayablesList> targetListTemp = payablesList;

List<String> listOfCategory = [];
List<String> listOfSupplier = [];

Map<String, Map<String, bool>> allCategoriesState = {};

bool fromFilter = false;

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

List<ExpensesList> expensesList = [];

double totalFixedExpensesCommitment = 0.0;
double totalFixedExpensesActualPaid = 0.0;

class FinancePayablesCollectionBIProvider with ChangeNotifier {
  List<PayablesList> _collectionList = [];
  List<PayablesList> get collectionList => _collectionList;
  void updateCollectionList(List<PayablesList> newCollectionList) {
    _collectionList = newCollectionList;
    notifyListeners();
  }
}

class FinancePayablesTargetCollectionBIProvider with ChangeNotifier {
  List<DebtorsAgingList> _targetList = [];
  List<DebtorsAgingList> get targetList => _targetList;
  void updateTargetList(List<DebtorsAgingList> newTargetList) {
    _targetList = newTargetList;
    notifyListeners();
  }
}

class ActualPayableProvider with ChangeNotifier {
  List<ModeOfPaymentList> _targetList = [];
  List<ModeOfPaymentList> get targetList => _targetList;
  void updateTargetList(List<ModeOfPaymentList> newTargetList) {
    _targetList = newTargetList;
    notifyListeners();
  }
}

class PayableTrialBalanceProvider with ChangeNotifier {
  List<ExpensesList> _collectionList = [];
  List<ExpensesList> get collectionList => _collectionList;
  void updateCollectionList(List<ExpensesList> newCollectionList) {
    _collectionList = newCollectionList;
    notifyListeners();
  }
}

class PayableSalesTargetProvider with ChangeNotifier {
  List<SalesTargetList> _salesTargetList = [];
  List<SalesTargetList> get salesTargetList => _salesTargetList;
  void updateSalesTargetList(List<SalesTargetList> newSalesTargetList) {
    _salesTargetList = newSalesTargetList;
    notifyListeners();
  }
}

class _PayableFinanceState extends State<PayableFinance> {
  int touchedIndex = -1;
  bool showDrillDownChart = false;

  double roundUpTo50Lakhs(double value) {
    const step = 5000000;
    return (value / step).ceil() * step.toDouble();
  }

  double roundDownTo50Lakhs(double value) {
    const step = 5000000;
    return (value / step).floor() * step.toDouble();
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

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
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
  }

  String formatTestDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
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

  SideTitles get _bottomTitlesPayables => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<PayablesGraphData> mData = payableGraphList.agingData;
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

  SideTitles get _bottomTitlesAdvancePaid => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<AdvancePaidToSupplierPayablesData> mData = receivableList.agingData;
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

  SideTitles get _bottomTitlesSupplierAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<SupplierAnalysisPayablesData> mData = supplierList.supplierData;
      text = mData.elementAt(value.toInt()).supplierName;
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

  SideTitles get _bottomTitlesSupplierCategoryAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<SupplierCategoryWiseAnalysisPayablesData> mData =
          supplierCategoryList.supplierCategoryData;
      text = mData.elementAt(value.toInt()).supplierCategoryName;
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

  SideTitles get _bottomTitlesDocumentType => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DocumentTypeData> mData = documentList.documentData;
      text = mData.elementAt(value.toInt()).documentType;
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

  SideTitles get _bottomTitlesbpGroup => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<SupplierCategoryWiseAnalysisPayablesData> mData =
          bpGroupList.supplierCategoryData;
      text = mData.elementAt(value.toInt()).supplierCategoryName;
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

  SideTitles get _bottomTitlesAdvanceVendors => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<SupplierAnalysisPayablesData> mData = advanceVendorList.supplierData;
      text = mData.elementAt(value.toInt()).supplierName;
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

  SideTitles get _bottomTitlesCapitalVendors => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<VendorsPaymentProjectionData> mData = capitalVendorsList.vendorData;
      text = mData.elementAt(value.toInt()).vendorName;
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

  SideTitles get _bottomTitlesFixedExpenses => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<SupplierCategoryWiseAnalysisPayablesData> mData =
          fixedExpensesList.supplierCategoryData;
      text = mData.elementAt(value.toInt()).supplierCategoryName;
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

  List<BarChartGroupData> _payablesChartData(List<PayablesGraphData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.agingGroupTotal,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _advancePaidChartData(
    List<AdvancePaidToSupplierPayablesData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.agingGroupTotal,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _supplierAnalysisChartData(
    List<SupplierAnalysisPayablesData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.balance,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _supplierCategoryAnalysisChartData(
    List<SupplierCategoryWiseAnalysisPayablesData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.balance,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _documentTypeChartData(List<DocumentTypeData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.balance,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _bpGroupChartData(
    List<SupplierCategoryWiseAnalysisPayablesData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.balance,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _advanceVendorChartData(
    List<SupplierAnalysisPayablesData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.balance,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _capitalVendorsChartData(
    List<VendorsPaymentProjectionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.balanceDue,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _fixedExpensesChartData(
    List<SupplierCategoryWiseAnalysisPayablesData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.balance,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _loadPayables(
    String UserName,
    String UserLevel,
    bool fromFilter,
  ) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<PayablesList> collectionList = [];
    try {
      if (!fromFilter) {
        do {
          var body = {
            "Index": index.toString(),
            "Limit": limit.toString(),
            "sapToken": DataManager.readSapToken(),
          };
          const apiUrl = '${ApiHelper.baseUrl}BicxoCreditorsAgingList';
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
            body: jsonEncode(body),
          );

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseJson = jsonDecode(response.body);
            if (responseJson["responseData"].toString().isNotEmpty) {
              List<PayablesList> newCollectionList =
                  (responseJson['responseData'] as List)
                      .map((item) => PayablesList.fromJson(item))
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
      }
      setState(() {
        context
            .read<FinancePayablesCollectionBIProvider>()
            .updateCollectionList(collectionList);
        if (int.parse(UserLevel) == 5) {
          payablesList = collectionList.toList();
        } else if (int.parse(UserLevel) == 4) {
          payablesList = collectionList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          payablesList = collectionList.toList();
        } else {
          payablesList = collectionList.toList();
        }

        payablesListMaster = collectionList.toList();

        List<String> trueCategoryOptions =
            (allCategoriesState['Category'] ?? {}).entries
                .where((entry) => entry.value)
                .map((entry) => entry.key)
                .toList();

        List<String> trueSupplierOptions =
            (allCategoriesState['Supplier'] ?? {}).entries
                .where((entry) => entry.value)
                .map((entry) => entry.key)
                .toList();

        List<PayablesList> filteredList = [];

        if (trueCategoryOptions.isNotEmpty) {
          filteredList = payablesList
              .where(
                (person) => trueCategoryOptions.contains(person.vendorGroup),
              )
              .toList();
          payablesList = filteredList;
        }

        if (trueSupplierOptions.isNotEmpty) {
          filteredList = payablesList
              .where(
                (person) => trueSupplierOptions.contains(person.vendorName),
              )
              .toList();
          payablesList = filteredList;
        }

        double payableSum = 0;
        double advanceSum = 0;
        double payablesSum = 0;
        List<PayablesList> currentMonthTarget = payablesList.where((target) {
          DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
          return dueon.isAtMost(currentMonthToDate!) &&
              target.ageingBrackets != "Future";
        }).toList();

        for (var target in currentMonthTarget.toList()) {
          double balance = double.tryParse(target.balance) ?? 0;
          double balanceAbs = balance;
          payableSum += balanceAbs;
          if (balance > 0) {
            advanceSum += balance;
          }
          if (balance < 0) {
            payablesSum += balance;
          }
        }

        payableStr = formatAmount(payablesSum.abs());

        advanceStr = formatAmount(advanceSum);
        payableAdvanceStr = formatAmount(payableSum.abs());
        payableAdvancePercentage =
            double.tryParse(
              ((advanceSum.abs() / (payableSum.abs())) * 100).toStringAsFixed(
                2,
              ),
            )?.ceil() ??
            0;
        if (payableAdvancePercentage > 100) {
          payableAdvancePercentage = 100;
        }

        var notOverDue = payablesList;
        for (var target in notOverDue.toList()) {
          String future = target.ageingBrackets;
          if (future == 'Future') {
            // notDue += balance;
          }
        }

        double netPayableSum = 0;

        for (var target in payablesList.toList()) {
          // overDueSum += balance;
          double balance = double.tryParse(target.balance) ?? 0;
          String future = target.ageingBrackets;
          netPayableSum += balance;
          if (future != "Future") {
            overDue += balance;
          }
          if (future == "Future") {
            notDue += balance;
          }
        }

        netPayable = /* notDue +*/ netPayableSum;
        netPayableStr = "";
        netPayableStr = formatAmount(netPayable.abs());
        // overDue = overDueSum;
        overDueStr = formatAmount(overDue.abs());
        notDueStr = formatAmount(notDue.abs());

        if (overDue == 0 || netPayable == 0) {
          netPayablePercentage = 0;
        } else {
          netPayablePercentage =
              double.tryParse(
                ((overDue / (netPayable)) * 100).toStringAsFixed(2),
              )?.ceil() ??
              0;
        }

        if (netPayablePercentage > 100) {
          netPayablePercentage = 100;
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

  Future<void> _loadExpenses(String userName, String userLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<ExpensesList> tmpTrialBalanceList = [];
    try {
      do {
        var body = {
          "FromDate": dateFilterFlag
              ? formatTestDate(fromDateFilter!)
              : formatTestDate(fiscalYearStartDate!),
          "ToDate": dateFilterFlag
              ? formatTestDate(toDateFilter!)
              : formatTestDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoTrialBalanceList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<ExpensesList> newTrialBalanceList =
                (responseJson['responseData'] as List)
                    .map((item) => ExpensesList.fromJson(item))
                    .toList();
            tmpTrialBalanceList.addAll(newTrialBalanceList);
            fetchedCount = newTrialBalanceList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else if (response.statusCode == 504) {
          await _loadExpenses(userName, userLevel);
        } else if (response.statusCode == 502) {
          await _loadExpenses(userName, userLevel);
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        context.read<PayableTrialBalanceProvider>().updateCollectionList(
          tmpTrialBalanceList,
        );
        if (expensesList.isEmpty) {
          expensesList = tmpTrialBalanceList.toList();
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

  Future<void> _loadModeOfPayment(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<ModeOfPaymentList> salesList = [];
    try {
      do {
        var body = {
          "FromDate": dateFilterFlag
              ? formatTestDate(fromDateFilter!)
              : formatTestDate(fiscalYearStartDate!),
          "ToDate": dateFilterFlag
              ? formatTestDate(toDateFilter!)
              : formatTestDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoPaymentAnalysisList';
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
            List<ModeOfPaymentList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => ModeOfPaymentList.fromJson(item))
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
        context.read<ActualPayableProvider>().updateTargetList(salesList);
        if (int.parse(UserLevel) == 5) {
          modeOfPayment = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          modeOfPayment = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          modeOfPayment = salesList.toList();
        } else {
          modeOfPayment = salesList.toList();
        }
      });
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _loadSalesTarget(String UserName, String UserLevel) async {
    final body = {
      "FromDate": dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!),
      "ToDate": dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!),
      "Index": 0,
      "Limit": 0,
      "sapToken": DataManager.readSapToken(),
    };
    const apiUrl = '${ApiHelper.baseUrl}BicxoSalesTargetList';
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
          List<dynamic> data = responseJson['responseData'];
          if (data.isNotEmpty) {
            List<SalesTargetList> newSalesTargetList = (data)
                .map((item) => SalesTargetList.fromJson(item))
                .toList();
            setState(() {
              List<String> menuNames = usersList
                  .where((element) => element.parentMenuId == 0)
                  .map((user) => user.menuName)
                  .toList();
              menuNames.insert(0, UserName);
              context.read<PayableSalesTargetProvider>().updateSalesTargetList(
                newSalesTargetList,
              );
              if (int.parse(UserLevel) == 5) {
                salesTarget = newSalesTargetList;
              } else if (int.parse(UserLevel) == 4) {
                salesTarget = newSalesTargetList;
              } else if (int.parse(UserLevel) <= 3 &&
                  int.parse(UserLevel) >= 2) {
                salesTarget = newSalesTargetList;
              } else {
                salesTarget = newSalesTargetList;
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
      } else {
        const snackBar = SnackBar(
          content: Text('Sales target details not found.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      const snackBar = SnackBar(
        content: Text('SAP Server down, Please try again after some time.'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _dateFilterTarget() async {
    DateFormat formatter = DateFormat('dd/MM/yyyy');

    setState(() {
      context.read<PayableTrialBalanceProvider>().updateCollectionList(
        expensesList,
      );
      context.read<ActualPayableProvider>().updateTargetList(modeOfPayment);
      context.read<FinancePayablesCollectionBIProvider>().updateCollectionList(
        payablesList,
      );

      payablesList = payablesList.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
        return ( /*dueon.isAtLeast(fromDateFilter!) &&*/ dueon.isAtMost(
          toDateFilter!,
        ));
      }).toList();
      modeOfPayment = modeOfPayment.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
        return ( /*dueon.isAtLeast(fromDateFilter!) &&*/ dueon.isAtMost(
          toDateFilter!,
        ));
      }).toList();
      expensesList = expensesList.where((target) {
        DateTime toDt = formatter.parse('30/${target.monthYear}');
        return ( /*toDt.isAtLeast(fromDateFilter!) &&*/ toDt.isAtMost(
          toDateFilter!,
        ));
      }).toList();
    });
  }

  AgingSummary summarizeCollectionTargets(
    Iterable<PayablesList> collectionTargetList,
  ) {
    AgingSummary summary = AgingSummary();
    double balance = 0;
    var overDueDays = 0;
    for (var element
        in collectionTargetList /*.where((element) => double.tryParse(element.future)! <= 0)*/ ) {
      overDueDays = int.tryParse(element.dueDays.replaceAll(' Days', '')) ?? 0;
      balance = double.tryParse(element.balance) ?? 0;
      if (balance < 0) {}
      if (overDueDays <= 30) {
        // summary.a0to30DaysTotal += (balance);
        summary.a0to30DaysTotal += double.tryParse(element.a0to30Days)!;
      } else if (overDueDays >= 31 && overDueDays <= 60) {
        // summary.a31to60DaysTotal += balance;
        summary.a31to60DaysTotal += double.tryParse(element.a31to60Days)!;
      } else if (overDueDays >= 61 && overDueDays <= 90) {
        // summary.a61to90DaysTotal += balance;
        summary.a61to90DaysTotal += double.tryParse(element.a61to90Days)!;
      } else if (overDueDays >= 91 && overDueDays <= 180) {
        // summary.a91to180DaysTotal += balance;
        summary.a91to180DaysTotal += double.tryParse(element.a91to180Days)!;
      } else if (overDueDays >= 181) {
        // summary.a181DaysTotal += balance;
        summary.a181DaysTotal += double.tryParse(element.a181Days)!;
      }
      // summary.afutureTotal += balance;
      summary.afutureTotal += double.tryParse(element.future)!;
    }
    return summary;
  }

  AgingSummary summarizeAdvancePaid(
    Iterable<PayablesList> collectionTargetList,
  ) {
    AgingSummary summary = AgingSummary();
    double balance = 0;
    var overDueDays = 0;
    for (var element in collectionTargetList.where(
      (element) =>
          (double.tryParse(element.future)! >= 0 &&
          (double.tryParse(element.a0to30Days)! >= 0) &&
          (double.tryParse(element.a31to60Days)! >= 0) &&
          (double.tryParse(element.a61to90Days)! >= 0) &&
          (double.tryParse(element.a91to180Days)! >= 0) &&
          (double.tryParse(element.a181Days)! >= 0)),
    )) {
      overDueDays = int.tryParse(element.dueDays.replaceAll(' Days', '')) ?? 0;
      balance = double.tryParse(element.balance) ?? 0;
      if (balance < 0) {}

      summary.afutureTotal += double.tryParse(element.future)!;

      if (overDueDays <= 30) {
        summary.a0to30DaysTotal += double.tryParse(element.a0to30Days)!;
      } else if (overDueDays >= 31 && overDueDays <= 60) {
        summary.a31to60DaysTotal += double.tryParse(element.a31to60Days)!;
      } else if (overDueDays >= 61 && overDueDays <= 90) {
        summary.a61to90DaysTotal += double.tryParse(element.a61to90Days)!;
      } else if (overDueDays >= 91 && overDueDays <= 180) {
        summary.a91to180DaysTotal += double.tryParse(element.a91to180Days)!;
      } else if (overDueDays >= 181) {
        summary.a181DaysTotal += double.tryParse(element.a181Days)!;
      }
    }
    return summary;
  }

  Future<void> _loadPayablesData(
    String payable,
    String advancePaid,
    String supplier,
    String supplierCategory,
    String documentType,
    String bpGroup,
  ) async {
    final fPayable = payable.toLowerCase();
    final fAdvance = advancePaid.toLowerCase();
    final fSupplier = supplier.toLowerCase();
    final fSupCat = supplierCategory.toLowerCase();
    final fDocType = documentType.toLowerCase();
    final fBpGroup = bpGroup.toLowerCase();

    final df = DateFormat('dd/MM/yyyy');

    final List<double> bucketSums = List<double>.filled(6, 0.0);

    final DateTime? effectiveCurrentMonthToDate = currentMonthToDate;

    for (final t in payablesList) {
      final dueOn = df.parse(t.postingDate);

      if (!dueOn.isAtMost(effectiveCurrentMonthToDate!)) continue;

      final tVendorNameLower = t.vendorName.toLowerCase();
      final tVendorGroupLower = t.vendorGroup.toLowerCase();
      final tDocumentTypeLower = t.documentType.toLowerCase();
      final tBpSubGroupLower = t.bpSubGroup.toLowerCase();
      final tAgeingBracketsLower = t.ageingBrackets.toLowerCase();

      if (fPayable.isNotEmpty && !tAgeingBracketsLower.contains(fPayable)) {
        continue;
      }
      if (fAdvance.isNotEmpty && !tAgeingBracketsLower.contains(fAdvance)) {
        continue;
      }

      if (fSupplier.isNotEmpty && tVendorNameLower != fSupplier) {
        continue;
      }
      if (fSupCat.isNotEmpty && tVendorGroupLower != fSupCat) {
        continue;
      }
      if (fDocType.isNotEmpty && tDocumentTypeLower != fDocType) {
        continue;
      }
      if (fBpGroup.isNotEmpty && tBpSubGroupLower != fBpGroup) {
        continue;
      }

      int idx;
      switch (t.ageingBrackets) {
        case "Future":
          idx = 0;
          break;
        case "0-30 Days":
          idx = 1;
          break;
        case "31-60 Days":
          idx = 2;
          break;
        case "61-90 Days":
          idx = 3;
          break;
        case "91-180 Days":
          idx = 4;
          break;
        default:
          idx = 5;
      }

      bucketSums[idx] += double.tryParse(t.balance) ?? 0.0;
    }

    final total = bucketSums.fold(0.0, (sum, v) => sum + v) * -1;
    final data = <PayablesGraphData>[];
    const labels = [
      "Future",
      "0-30 Days",
      "31-60 Days",
      "61-90 Days",
      "91-180 Days",
      "180+",
    ];

    for (var i = 0; i < 6; i++) {
      final groupTotal = bucketSums[i] * -1;
      data.add(
        PayablesGraphData(
          agingGroup: labels[i],
          agingGroupTotal: double.parse(groupTotal.toStringAsFixed(2)),
          agingPercentage: total != 0
              ? double.parse(((groupTotal / total) * 100).toStringAsFixed(2))
              : 0.0,
          agingTotal: total,
        ),
      );
    }

    payableGraphList = PayablesGraphList(agingData: data);
  }

  Future<void> _loadAdvancePaidData(
    String payable,
    String advancePaid,
    String supplier,
    String supplierCategory,
    String documentType,
    String bpGroup,
  ) async {
    final fPayable = payable.toLowerCase();
    final fAdvance = advancePaid.toLowerCase();
    final fSupplier = supplier.toLowerCase();
    final fSupCat = supplierCategory.toLowerCase();
    final fDocType = documentType.toLowerCase();
    final fBpGroup = bpGroup.toLowerCase();

    final df = DateFormat('dd/MM/yyyy');

    final List<double> bucketSums = List<double>.filled(6, 0.0);

    final DateTime? effectiveCurrentMonthToDate = currentMonthToDate;

    for (final t in payablesList) {
      final dueOn = df.parse(t.postingDate);
      if (!dueOn.isAtMost(effectiveCurrentMonthToDate!)) {
        continue;
      }

      final tAgeingBracketsLower = t.ageingBrackets.toLowerCase();
      final tVendorNameLower = t.vendorName.toLowerCase();
      final tVendorGroupLower = t.vendorGroup.toLowerCase();
      final tDocumentTypeLower = t.documentType.toLowerCase();
      final tBpSubGroupLower = t.bpSubGroup.toLowerCase();

      if (fPayable.isNotEmpty && !tAgeingBracketsLower.contains(fPayable)) {
        continue;
      }
      if (fAdvance.isNotEmpty && !tAgeingBracketsLower.contains(fAdvance)) {
        continue;
      }

      if (fSupplier.isNotEmpty && tVendorNameLower != fSupplier) {
        continue;
      }
      if (fSupCat.isNotEmpty && tVendorGroupLower != fSupCat) {
        continue;
      }
      if (fDocType.isNotEmpty && tDocumentTypeLower != fDocType) {
        continue;
      }
      if (fBpGroup.isNotEmpty && tBpSubGroupLower != fBpGroup) {
        continue;
      }

      int idx;
      switch (t.ageingBrackets) {
        case "Future":
          idx = 0;
          break;
        case "0-30 Days":
          idx = 1;
          break;
        case "31-60 Days":
          idx = 2;
          break;
        case "61-90 Days":
          idx = 3;
          break;
        case "91-180 Days":
          idx = 4;
          break;
        default:
          idx = 5;
      }

      bucketSums[idx] += (double.tryParse(t.balance) ?? 0.0).abs();
    }

    final total = bucketSums.fold(0.0, (sum, v) => sum + v);

    final labels = [
      "Future",
      "0-30 Days",
      "31-60 Days",
      "61-90 Days",
      "91-180 Days",
      "180+",
    ];
    final List<AdvancePaidToSupplierPayablesData> data = [];

    for (var i = 0; i < 6; i++) {
      final grpTotal = bucketSums[i];
      data.add(
        AdvancePaidToSupplierPayablesData(
          agingGroup: labels[i],
          agingGroupTotal: double.parse(grpTotal.toStringAsFixed(2)),
          agingPercentage: total != 0
              ? double.parse(((grpTotal / total) * 100).toStringAsFixed(2))
              : 0.0,
          agingTotal: total,
        ),
      );
    }

    receivableList = AdvancePaidToSupplierPayablesList(agingData: data);
  }

  Future<void> _loadSupplierAnalysis(
    String payable,
    String advancePaid,
    String supplier,
    String supplierCategory,
    String documentType,
    String bpGroup,
  ) async {
    final fPayable = payable.toLowerCase();
    final fAdvance = advancePaid.toLowerCase();
    final fSupplier = supplier.toLowerCase();
    final fSupCat = supplierCategory.toLowerCase();
    final fDocType = documentType.toLowerCase();
    final fBpGroup = bpGroup.toLowerCase();

    final df = DateFormat('dd/MM/yyyy');

    final Map<String, double> balanceByVendor = {};
    final Map<String, String> nameByVendor = {};

    final DateTime? effectiveCurrentMonthToDate = currentMonthToDate;

    for (final t in payablesList) {
      final dueOn = df.parse(t.postingDate);
      if (!dueOn.isAtMost(effectiveCurrentMonthToDate!)) {
        continue;
      }

      final tAgeingBracketsLower = t.ageingBrackets.toLowerCase();
      final tVendorNameLower = t.vendorName.toLowerCase();
      final tVendorGroupLower = t.vendorGroup.toLowerCase();
      final tDocumentTypeLower = t.documentType.toLowerCase();
      final tBpSubGroupLower = t.bpSubGroup.toLowerCase();

      if (fPayable.isNotEmpty && !tAgeingBracketsLower.contains(fPayable)) {
        continue;
      }
      if (fAdvance.isNotEmpty && !tAgeingBracketsLower.contains(fAdvance)) {
        continue;
      }

      if (fSupplier.isNotEmpty && tVendorNameLower != fSupplier) {
        continue;
      }
      if (fSupCat.isNotEmpty && tVendorGroupLower != fSupCat) {
        continue;
      }
      if (fDocType.isNotEmpty && tDocumentTypeLower != fDocType) {
        continue;
      }
      if (fBpGroup.isNotEmpty && tBpSubGroupLower != fBpGroup) {
        continue;
      }

      final amt = double.tryParse(t.balance) ?? 0.0;
      final code = t.vendorCode;

      balanceByVendor.update(code, (value) => value + amt, ifAbsent: () => amt);
      nameByVendor[code] = t.vendorName;
    }

    final List<SupplierAnalysisPayablesData> customerWiseDataList = [];
    balanceByVendor.forEach((code, sum) {
      customerWiseDataList.add(
        SupplierAnalysisPayablesData(
          supplierName: nameByVendor[code]!,
          balance: sum * -1,
        ),
      );
    });
    customerWiseDataList.sort((a, b) => b.balance.compareTo(a.balance));

    supplierList = SupplierAnalysisPayablesList(
      supplierData: customerWiseDataList,
    );

    if (listOfSupplier.isEmpty) {
      listOfSupplier = customerWiseDataList.map((e) => e.supplierName).toList();
    }
  }

  Future<void> _loadVendorPaymentProjection() async {
    final df = DateFormat('dd/MM/yyyy');

    final DateTime? effectiveCurrentMonthToDate = currentMonthToDate;

    final Map<String, Map<String, dynamic>> aggregatedPayableData = {};

    for (final payableItem in payablesList) {
      final dueOn = df.parse(payableItem.postingDate);

      if (!dueOn.isAtMost(effectiveCurrentMonthToDate!)) {
        continue;
      }

      final vendorCode = payableItem.vendorCode;
      final vendorName = payableItem.vendorName;

      aggregatedPayableData.putIfAbsent(
        vendorCode,
        () => {
          'vendorCode': vendorCode,
          'vendorName': vendorName,
          'balance': 0.0,
          'a0to30': 0.0,
          'a31to60': 0.0,
          'a61to90': 0.0,
          'a90to180': 0.0,
          'a180above': 0.0,
        },
      );

      final vendorData = aggregatedPayableData[vendorCode]!;

      vendorData['balance'] =
          (vendorData['balance'] as double) +
          (double.tryParse(payableItem.balance) ?? 0.0);

      final overDueDaysString = payableItem.dueDays.replaceAll(' Days', '');
      final overDueDays = int.tryParse(overDueDaysString) ?? 0;

      if (overDueDays <= 30) {
        vendorData['a0to30'] =
            (vendorData['a0to30'] as double) +
            (double.tryParse(payableItem.a0to30Days) ?? 0.0);
      } else if (overDueDays >= 31 && overDueDays <= 60) {
        vendorData['a31to60'] =
            (vendorData['a31to60'] as double) +
            (double.tryParse(payableItem.a31to60Days) ?? 0.0);
      } else if (overDueDays >= 61 && overDueDays <= 90) {
        vendorData['a61to90'] =
            (vendorData['a61to90'] as double) +
            (double.tryParse(payableItem.a61to90Days) ?? 0.0);
      } else if (overDueDays >= 91 && overDueDays <= 180) {
        vendorData['a90to180'] =
            (vendorData['a90to180'] as double) +
            (double.tryParse(payableItem.a91to180Days) ?? 0.0);
      } else if (overDueDays >= 181) {
        vendorData['a180above'] =
            (vendorData['a180above'] as double) +
            (double.tryParse(payableItem.a181Days) ?? 0.0);
      }
    }

    final Map<String, double> actualPayableByVendorName = {};
    for (final paymentEntry in modeOfPayment) {
      final dueOn = df.parse(paymentEntry.postingDate);

      if (dueOn.isAtMost(effectiveCurrentMonthToDate!)) {
        actualPayableByVendorName.update(
          paymentEntry.vendorName,
          (value) => value + (double.tryParse(paymentEntry.total) ?? 0.0),
          ifAbsent: () => (double.tryParse(paymentEntry.total) ?? 0.0),
        );
      }
    }

    final List<VendorsPaymentProjectionData> vendorWiseData = [];
    for (final entry in aggregatedPayableData.values) {
      final vendorName = entry['vendorName'] as String;
      final vendorCode = entry['vendorCode'] as String;

      final balanceDue = entry['balance'] as double;
      final a0to30 = entry['a0to30'] as double;
      final a31to60 = entry['a31to60'] as double;
      final a61to90 = entry['a61to90'] as double;
      final a90to180 = entry['a90to180'] as double;
      final a180above = entry['a180above'] as double;

      final actualPayable = actualPayableByVendorName[vendorName] ?? 0.0;

      vendorWiseData.add(
        VendorsPaymentProjectionData(
          vendorName: vendorName,
          vendorCode: vendorCode,
          balanceDue: balanceDue,
          a0to30: a0to30,
          a31to60: a31to60,
          a61to90: a61to90,
          a90to180: a90to180,
          a180above: a180above,
          commitment: 0,
          actualPayable: actualPayable,
        ),
      );
    }

    vendorWiseData.sort((a, b) => a.vendorCode.compareTo(b.vendorCode));
    vendorProjectionList = VendorsPaymentProjectionList(
      vendorData: vendorWiseData,
    );

    if (listOfSupplier.isEmpty) {
      listOfSupplier = supplierList.supplierData
          .map((ele) => ele.supplierName)
          .toList();
    }
  }

  Future<void> _loadSupplierCategoryAnalysis(
    String payable,
    String advancePaid,
    String supplier,
    String supplierCategory,
    String documentType,
    String bpGroup,
  ) async {
    final fPayable = payable.toLowerCase();
    final fAdvance = advancePaid.toLowerCase();
    final fSupplier = supplier.toLowerCase();
    final fSupCat = supplierCategory.toLowerCase();
    final fDocType = documentType.toLowerCase();
    final fBpGroup = bpGroup.toLowerCase();

    final df = DateFormat('dd/MM/yyyy');

    final DateTime? effectiveCurrentMonthToDate = currentMonthToDate;

    final List<PayablesList> tempFilteredList = [];

    for (final target in payablesList) {
      final dueOn = df.parse(target.postingDate);
      if (!dueOn.isAtMost(effectiveCurrentMonthToDate!)) {
        continue;
      }

      final targetAgeingBracketsLower = target.ageingBrackets.toLowerCase();
      final targetVendorNameLower = target.vendorName.toLowerCase();
      final targetVendorGroupLower = target.vendorGroup.toLowerCase();
      final targetDocumentTypeLower = target.documentType.toLowerCase();
      final targetBpSubGroupLower = target.bpSubGroup.toLowerCase();

      if (fPayable.isNotEmpty &&
          !targetAgeingBracketsLower.contains(fPayable)) {
        continue;
      }
      if (fAdvance.isNotEmpty &&
          !targetAgeingBracketsLower.contains(fAdvance)) {
        continue;
      }
      if (fSupplier.isNotEmpty && targetVendorNameLower != fSupplier) {
        continue;
      }
      if (fSupCat.isNotEmpty && targetVendorGroupLower != fSupCat) {
        continue;
      }
      if (fDocType.isNotEmpty && targetDocumentTypeLower != fDocType) {
        continue;
      }
      if (fBpGroup.isNotEmpty && targetBpSubGroupLower != fBpGroup) {
        continue;
      }

      tempFilteredList.add(target);
    }

    final Map<String, double> balanceByGroup = {};
    for (final item in tempFilteredList) {
      final group = item.vendorGroup;
      final amt = double.tryParse(item.balance) ?? 0.0;
      balanceByGroup.update(group, (value) => value + amt, ifAbsent: () => amt);
    }

    final List<SupplierCategoryWiseAnalysisPayablesData> customerWiseDataList =
        [];
    balanceByGroup.forEach((group, sum) {
      customerWiseDataList.add(
        SupplierCategoryWiseAnalysisPayablesData(
          supplierCategoryName: group,
          balance: sum * -1,
        ),
      );
    });
    customerWiseDataList.sort((a, b) => b.balance.compareTo(a.balance));

    supplierCategoryList = SupplierCategoryWiseAnalysisPayablesList(
      supplierCategoryData: customerWiseDataList,
    );

    if (listOfCategory.isEmpty) {
      listOfCategory = supplierCategoryList.supplierCategoryData
          .map(
            (ele) => ele.supplierCategoryName.length >= 7
                ? ele.supplierCategoryName.substring(7)
                : ele.supplierCategoryName,
          )
          .toList();
    }
  }

  Future<void> _loadbpGroup(
    String payable,
    String advancePaid,
    String supplier,
    String supplierCategory,
    String documentType,
    String bpGroup,
  ) async {
    final fPayable = payable.toLowerCase();
    final fAdvance = advancePaid.toLowerCase();
    final fSupplier = supplier.toLowerCase();
    final fSupCat = supplierCategory.toLowerCase();
    final fDocType = documentType.toLowerCase();
    final fBpGroup = bpGroup.toLowerCase();

    final df = DateFormat('dd/MM/yyyy');

    final DateTime? effectiveCurrentMonthToDate = currentMonthToDate;

    final Map<String, double> balanceByGroup = {};
    final Map<String, double> commitmentByGroup = {};
    final Map<String, double> actualByGroup = {};

    for (final t in payablesList) {
      final dueOn = df.parse(t.postingDate);
      if (!dueOn.isAtMost(effectiveCurrentMonthToDate!)) continue;

      final tAgeingBracketsLower = t.ageingBrackets.toLowerCase();
      final tVendorNameLower = t.vendorName.toLowerCase();
      final tVendorGroupLower = t.vendorGroup.toLowerCase();
      final tDocumentTypeLower = t.documentType.toLowerCase();
      final tBpSubGroupLower = t.bpSubGroup.toLowerCase();

      if (fPayable.isNotEmpty && !tAgeingBracketsLower.contains(fPayable)) {
        continue;
      }
      if (fAdvance.isNotEmpty && !tAgeingBracketsLower.contains(fAdvance)) {
        continue;
      }
      if (fSupplier.isNotEmpty && tVendorNameLower != fSupplier) {
        continue;
      }
      if (fSupCat.isNotEmpty && tVendorGroupLower != fSupCat) {
        continue;
      }
      if (fDocType.isNotEmpty && tDocumentTypeLower != fDocType) {
        continue;
      }
      if (fBpGroup.isNotEmpty && tBpSubGroupLower != fBpGroup) {
        continue;
      }

      final grp = t.bpSubGroup;
      final bal = double.tryParse(t.balance) ?? 0.0;
      final com = double.tryParse(t.commitment) ?? 0.0;

      balanceByGroup.update(grp, (value) => value + bal, ifAbsent: () => bal);
      commitmentByGroup.update(
        grp,
        (value) => value + com,
        ifAbsent: () => com,
      );
    }

    for (final p in modeOfPayment) {
      final paidOn = df.parse(p.postingDate);
      if (!paidOn.isAtMost(effectiveCurrentMonthToDate!)) continue;

      final grp = p.vendorName;

      final amt = double.tryParse(p.total) ?? 0.0;

      actualByGroup.update(grp, (value) => value + amt, ifAbsent: () => amt);
    }

    final allowed = {"Vendors", "Advance Vendors", "Capital Vendors"};
    double othersBal = 0, othersCom = 0, othersAct = 0;
    final List<SupplierCategoryWiseAnalysisPayablesData> list = [];

    final allGroupKeys = <String>{};
    allGroupKeys.addAll(balanceByGroup.keys);
    allGroupKeys.addAll(commitmentByGroup.keys);
    allGroupKeys.addAll(actualByGroup.keys);

    for (final grp in allGroupKeys) {
      final balSum = balanceByGroup[grp] ?? 0.0;
      final comSum = commitmentByGroup[grp] ?? 0.0;
      final actSum = actualByGroup[grp] ?? 0.0;

      if (allowed.contains(grp)) {
        list.add(
          SupplierCategoryWiseAnalysisPayablesData(
            supplierCategoryName: grp,
            balance: balSum * -1,
            commitment: comSum,
            actualPaid: actSum,
          ),
        );
      } else {
        othersBal += balSum * -1;
        othersCom += comSum;
        othersAct += actSum;
      }
    }

    if (othersBal != 0 || othersCom != 0 || othersAct != 0) {
      list.add(
        SupplierCategoryWiseAnalysisPayablesData(
          supplierCategoryName: "Others",
          balance: othersBal,
          commitment: othersCom,
          actualPaid: othersAct,
        ),
      );
    }

    list.add(
      SupplierCategoryWiseAnalysisPayablesData(
        supplierCategoryName: "Fixed Expenses",
        balance: totalFixedExpensesCommitment * -1,
        commitment: totalFixedExpensesCommitment,
        actualPaid: totalFixedExpensesActualPaid,
      ),
    );

    list.sort((a, b) => b.balance.compareTo(a.balance));
    bpGroupList = SupplierCategoryWiseAnalysisPayablesList(
      supplierCategoryData: list,
    );
  }

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  Future<void> _loadFixedExpenses() async {
    List<SupplierCategoryWiseAnalysisPayablesData> customerWiseDataList = [];
    DateFormat formatter = DateFormat('dd/MM/yyyy');

    String getCurrentFinancialYearSuffix() {
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;
      int startYear = (month >= 4) ? year : year - 1;
      int endYear = startYear + 1;
      return "FY${startYear % 100}-${endYear % 100}-ET";
    }

    List<SalesTargetList> tempTarget = salesTarget
        .where((test) => test.financialYear == getCurrentFinancialYearSuffix())
        .toList();

    List<ExpensesList> customerTargetList = expensesList.where((target) {
      if (target.monthYear.isEmpty) return false;
      try {
        DateTime toDt = formatter.parse('01/${target.monthYear}');
        DateTime lastDayOfMonth = DateTime(toDt.year, toDt.month + 1, 0);
        return lastDayOfMonth.isBefore(
              currentMonthToDate!.add(const Duration(days: 1)),
            ) &&
            target.subSubGroup.isNotEmpty;
      } catch (e) {
        return false;
      }
    }).toList();

    var currentMonthActualPayable = modeOfPayment.where((target) {
      if (target.postingDate.isEmpty) return false;
      try {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
        return dueon.isAtMost(currentMonthToDate!);
      } catch (e) {
        return false;
      }
    });

    String month = getMonthName(DateTime.now().month);
    Set<String> allVendorGroups = {};

    for (var expense in customerTargetList) {
      allVendorGroups.add(expense.subSubGroup.trim().toUpperCase());
    }
    for (var target in tempTarget) {
      if (target.salesRep.toUpperCase().endsWith(" TARGET")) {
        String vendorName = target.salesRep
            .substring(0, target.salesRep.length - " TARGET".length)
            .trim()
            .toUpperCase();
        allVendorGroups.add(vendorName);
      }
    }

    Set<String> processedGroups = {};

    for (String vendorGroup in allVendorGroups) {
      if (!processedGroups.add(vendorGroup)) continue;

      double balance = customerTargetList
          .where((e) => e.subSubGroup.trim().toUpperCase() == vendorGroup)
          .fold(0.0, (sum, e) => sum + (double.tryParse(e.balance) ?? 0.0));

      double commitment = tempTarget
          .where(
            (e) => e.salesRep.trim().toUpperCase() == "$vendorGroup TARGET",
          )
          .fold(
            0.0,
            (sum, e) =>
                sum + (double.tryParse(e.getTargetForMonth(month)) ?? 0.0),
          );

      // if (commitment == 0) continue;

      double actualPayable = currentMonthActualPayable
          .where((e) => e.bpSubGroup.trim().toUpperCase() == vendorGroup)
          .fold(0.0, (sum, e) => sum + (double.tryParse(e.total) ?? 0.0));

      totalFixedExpensesCommitment += commitment;
      totalFixedExpensesActualPaid += actualPayable;

      customerWiseDataList.add(
        SupplierCategoryWiseAnalysisPayablesData(
          supplierCategoryName: vendorGroup,
          balance: balance.abs(),
          commitment: commitment,
          actualPaid: actualPayable,
        ),
      );
    }

    customerWiseDataList.sort((a, b) => b.balance.compareTo(a.balance));

    fixedExpensesList = SupplierCategoryWiseAnalysisPayablesList(
      supplierCategoryData: customerWiseDataList,
    );
  }

  Future<void> _loadAdvanceVendors() async {
    List<SupplierAnalysisPayablesData> customerWiseDataList = [];
    var customerTargetList = const Iterable.empty();
    var currentMonthActualPayable = const Iterable.empty();
    double balance = 0.0;
    String vendorCode = "";
    String vendorName = "";

    customerTargetList = payablesList.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return dueon.isAtMost(currentMonthToDate!) &&
          target.bpSubGroup == "Advance Vendors";
    });

    currentMonthActualPayable = modeOfPayment.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return /*dueon.isAtLeast(currentMonthFromDate!) &&*/ dueon.isAtMost(
        currentMonthToDate!,
      );
    });

    Set<String> processedVendorCodes = {};
    for (var customer in customerTargetList.toList()) {
      if (!processedVendorCodes.contains(customer.vendorCode)) {
        vendorCode = customer.vendorCode;
        vendorName = customer.vendorName;
        for (var sales in customerTargetList.where(
          (saleelement) => saleelement.vendorCode == vendorCode,
        )) {
          balance += double.tryParse(sales.balance) ?? 0;
        }

        double actualPayable = currentMonthActualPayable
            .where((entry) => entry.vendorName == vendorName)
            .fold(0.0, (sum, entry) => sum + double.parse(entry.total));

        customerWiseDataList.add(
          SupplierAnalysisPayablesData(
            supplierName: vendorName,
            balance: balance.abs(),
            actualPaid: actualPayable,
          ),
        );
        processedVendorCodes.add(vendorCode);
      }
      vendorCode = "";
      vendorName = "";
      balance = 0;
    }

    customerWiseDataList.sort((a, b) => b.balance.compareTo(a.balance));
    advanceVendorList = SupplierAnalysisPayablesList(
      supplierData: customerWiseDataList,
    );
  }

  Future<void> _loadCapitalVendors() async {
    List<VendorsPaymentProjectionData> vendorWiseData = [];
    var customerTargetList = const Iterable.empty();
    var currentMonthActualPayable = const Iterable.empty();
    double balance = 0.0;
    var overDueDays = 0;
    double a0to30 = 0.0;
    double a31to60 = 0;
    double a61to90 = 0;
    double a90to180 = 0;
    double a180above = 0;
    String vendorCode = "";
    String vendorName = "";
    double commitment = 0;

    customerTargetList = payablesList.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return dueon.isAtMost(currentMonthToDate!) &&
          target.bpSubGroup == "Capital Vendors";
    });

    currentMonthActualPayable = modeOfPayment.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return /*dueon.isAtLeast(currentMonthFromDate!) &&*/ dueon.isAtMost(
        currentMonthToDate!,
      );
    });

    Set<String> processedVendorCodes = {};
    for (var customer in customerTargetList.toList()) {
      if (!processedVendorCodes.contains(customer.vendorCode)) {
        vendorCode = customer.vendorCode;
        vendorName = customer.vendorName;
        for (var sales in customerTargetList.where(
          (saleelement) => saleelement.vendorCode == vendorCode,
        )) {
          balance += double.tryParse(sales.balance) ?? 0;
          overDueDays =
              int.tryParse(sales.dueDays.replaceAll(' Days', '')) ?? 0;
          commitment = double.tryParse(sales.commitment) ?? 0;
          if (balance < 0) {}
          if (overDueDays <= 30) {
            a0to30 += double.tryParse(sales.a0to30Days)!;
          } else if (overDueDays >= 31 && overDueDays <= 60) {
            a31to60 += double.tryParse(sales.a31to60Days)!;
          } else if (overDueDays >= 61 && overDueDays <= 90) {
            a61to90 += double.tryParse(sales.a61to90Days)!;
          } else if (overDueDays >= 91 && overDueDays <= 180) {
            a90to180 += double.tryParse(sales.a91to180Days)!;
          } else if (overDueDays >= 181) {
            a180above += double.tryParse(sales.a181Days)!;
          }
        }

        double actualPayable = currentMonthActualPayable
            .where((entry) => entry.vendorName == vendorName)
            .fold(0.0, (sum, entry) => sum + double.parse(entry.total));

        vendorWiseData.add(
          VendorsPaymentProjectionData(
            vendorName: vendorName,
            vendorCode: vendorCode,
            balanceDue: balance,
            a0to30: a0to30,
            a31to60: a31to60,
            a61to90: a61to90,
            a90to180: a90to180,
            a180above: a180above,
            commitment: commitment,
            actualPayable: actualPayable,
          ),
        );
        processedVendorCodes.add(vendorCode);
      }
      vendorCode = "";
      vendorName = "";
      balance = 0;
      a0to30 = 0;
      a31to60 = 0;
      a61to90 = 0;
      a90to180 = 0;
      a180above = 0;
    }

    vendorWiseData.sort((a, b) => a.vendorCode.compareTo(b.vendorCode));
    capitalVendorsList = VendorsPaymentProjectionList(
      vendorData: vendorWiseData,
    );
  }

  // Future<void> _loadDocumentTypeAnalysis(String payable, String advancePaid,
  //     String supplier, String supplierCategory, String documentType, String bpGroup,) async {
  //   List<DocumentTypeData> customerWiseDataList = [];
  //   var customerTargetList = const Iterable.empty();
  //   double balance = 0.0;
  //   String docType = "";
  //
  //   customerTargetList = payablesList.where((target) {
  //     DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
  //     return dueon.isAtMost(currentMonthToDate!);
  //   });
  //
  //   customerTargetList = filterPayablesList(
  //     customerTargetList.cast<PayablesList>().toList(),
  //     payable: payable,
  //     advancePaid: advancePaid,
  //     supplier: supplier,
  //     supplierCategory: supplierCategory,
  //     documentType: documentType,
  //   );
  //
  //   Set<String> processedCustomerCodes = {};
  //   for (var customer in customerTargetList.toList()) {
  //     if (!processedCustomerCodes.contains(customer.documentType)) {
  //       docType = customer.documentType;
  //       for (var sales in customerTargetList
  //           .where((saleelement) => saleelement.documentType == docType)) {
  //         balance += double.tryParse(sales.balance) ?? 0;
  //       }
  //
  //       customerWiseDataList.add(DocumentTypeData(
  //         documentType: docType == "" ? "Others" : docType,
  //         balance: balance.abs(),
  //       ));
  //       processedCustomerCodes.add(docType);
  //     }
  //     docType = "";
  //     balance = 0;
  //   }
  //
  //   documentList = DocumentTypeList(documentData: customerWiseDataList);
  // }

  Future<void> _loadDocumentTypeAnalysis(
    String payable,
    String advancePaid,
    String supplier,
    String supplierCategory,
    String documentType,
    String bpGroup,
  ) async {
    final fPayable = payable.toLowerCase();
    final fAdvance = advancePaid.toLowerCase();
    final fSupplier = supplier.toLowerCase();
    final fSupCat = supplierCategory.toLowerCase();
    final fDocType = documentType.toLowerCase();
    final fBpGroup = bpGroup.toLowerCase();

    final df = DateFormat('dd/MM/yyyy');

    final Map<String, double> balanceByDoc = {};

    for (final t in payablesList) {
      final dueOn = df.parse(t.postingDate);
      if (!dueOn.isAtMost(currentMonthToDate!)) continue;

      final dd = t.ageingBrackets.toLowerCase();
      if (fPayable.isNotEmpty && !dd.contains(fPayable)) continue;
      if (fAdvance.isNotEmpty && !dd.contains(fAdvance)) continue;
      if (fSupplier.isNotEmpty && t.vendorName.toLowerCase() != fSupplier) {
        continue;
      }
      if (fSupCat.isNotEmpty && t.vendorGroup.toLowerCase() != fSupCat) {
        continue;
      }
      if (fDocType.isNotEmpty && t.documentType.toLowerCase() != fDocType) {
        continue;
      }
      if (fBpGroup.isNotEmpty && t.bpSubGroup.toLowerCase() != fBpGroup) {
        continue;
      }

      final doc = t.documentType.isEmpty ? "Others" : t.documentType;
      final amt = double.tryParse(t.balance) ?? 0.0;
      balanceByDoc[doc] = (balanceByDoc[doc] ?? 0.0) + amt;
    }

    final List<DocumentTypeData> customerWiseDataList =
        balanceByDoc.entries
            .map(
              (e) =>
                  DocumentTypeData(documentType: e.key, balance: e.value * -1),
            )
            .toList()
          ..sort((a, b) => b.balance.compareTo(a.balance));

    documentList = DocumentTypeList(documentData: customerWiseDataList);
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
    await _loadPayables(userName, userLevel, fromFilter);
    await _loadExpenses(userName, userLevel);
    await _loadModeOfPayment(userName, userLevel);
    await _loadSalesTarget(userName, userLevel);
    await _loadPayablesData("", "", "", "", "", "");
    await _loadAdvancePaidData("", "", "", "", "", "");
    await _loadSupplierAnalysis("", "", "", "", "", "");
    await _loadVendorPaymentProjection();
    await _loadSupplierCategoryAnalysis("", "", "", "", "", "");
    await _loadDocumentTypeAnalysis("", "", "", "", "", "");
    await _loadFixedExpenses();
    await _loadbpGroup("", "", "", "", "", "");
    await _loadAdvanceVendors();
    await _loadCapitalVendors();

    filterOptions = [listOfCategory, listOfSupplier, []];

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
    chartDataLoadedPayables = true;
  }

  List<PayablesList> filterPayablesList(
    List<PayablesList> payableList, {
    String? payable,
    String? advancePaid,
    String? supplier,
    String? supplierCategory,
    String? documentType,
  }) {
    List<PayablesList> filteredCollectionTargetList = [];
    double dueFromReceivable = 0.0;
    double dueToReceivable = double.infinity;
    double dueFromAdvance = 0.0;
    double dueToAdvance = double.infinity;
    if (payable != null || payable != "") {
      if (payable == "0-30") {
        dueFromReceivable = 0;
        dueToReceivable = 30;
      } else if (payable == "31-60") {
        dueFromReceivable = 31;
        dueToReceivable = 60;
      } else if (payable == "61-90") {
        dueFromReceivable = 61;
        dueToReceivable = 90;
      } else if (payable == "91-180") {
        dueFromReceivable = 91;
        dueToReceivable = 180;
      } else if (payable == "180+") {
        dueFromReceivable = 181;
        dueToReceivable = double.infinity;
      }
    }
    if (advancePaid != null || advancePaid != "") {
      if (advancePaid == "0-30") {
        dueFromAdvance = 0;
        dueToAdvance = 30;
      } else if (advancePaid == "31-60") {
        dueFromAdvance = 31;
        dueToAdvance = 60;
      } else if (advancePaid == "61-90") {
        dueFromAdvance = 61;
        dueToAdvance = 90;
      } else if (advancePaid == "91-180") {
        dueFromAdvance = 91;
        dueToAdvance = 180;
      } else if (advancePaid == "180+") {
        dueFromAdvance = 181;
        dueToAdvance = double.infinity;
      }
    }

    for (var target in payableList) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      Duration difference = postingDate.difference(DateTime.now());
      int overDueDayAdvance = difference.inDays.abs();
      double overDueDayReceivables =
          double.tryParse(target.dueDays.replaceAll(' Days', '')) ?? 0;

      if ((supplier == null ||
              supplier.isEmpty ||
              target.vendorName == supplier) &&
          (supplierCategory == null ||
              supplierCategory.isEmpty ||
              target.vendorGroup == supplierCategory) &&
          (documentType == null ||
              documentType.isEmpty ||
              target.documentType == documentType) &&
          (payable == null ||
              payable.isEmpty ||
              (overDueDayReceivables >= dueFromReceivable &&
                  overDueDayReceivables <= dueToReceivable)) &&
          (advancePaid == null ||
              advancePaid.isEmpty ||
              (overDueDayAdvance >= dueFromAdvance &&
                  overDueDayAdvance <= dueToAdvance))) {
        filteredCollectionTargetList.add(target);
      }
    }
    return filteredCollectionTargetList;
  }

  Future<void> loadDataWithFilter(
    String? payable,
    String? advancePaid,
    String? supplier,
    String? supplierCategory,
    String? documentType,
    String? bpGroup,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    await _loadPayablesData(
      payable!,
      advancePaid!,
      supplier!,
      supplierCategory!,
      documentType!,
      bpGroup!,
    );
    await _loadAdvancePaidData(
      payable,
      advancePaid,
      supplier,
      supplierCategory,
      documentType,
      bpGroup,
    );
    await _loadSupplierAnalysis(
      payable,
      advancePaid,
      supplier,
      supplierCategory,
      documentType,
      bpGroup,
    );
    await _loadSupplierCategoryAnalysis(
      payable,
      advancePaid,
      supplier,
      supplierCategory,
      documentType,
      bpGroup,
    );
    await _loadDocumentTypeAnalysis(
      payable,
      advancePaid,
      supplier,
      supplierCategory,
      documentType,
      bpGroup,
    );
    await _loadVendorPaymentProjection();
    await _loadFixedExpenses();
    await _loadbpGroup(
      payable,
      advancePaid,
      supplier,
      supplierCategory,
      documentType,
      bpGroup,
    );
    await _loadAdvanceVendors();
    await _loadCapitalVendors();

    chartDataLoadedPayables = true;
  }

  Future<void> removeFilter() async {
    setState(() {
      chartDataLoadedPayables = false;
    });
    clearVariables();
    LoadDates();
    allCategoriesState.forEach((category, options) {
      options.updateAll((key, value) => false);
    });
    loadDataFuture = loadData("");
    setState(() {
      chartDataLoadedPayables = false;
    });
  }

  void clearVariables() {
    setState(() {
      chartDataLoadedPayables = false;
      payableGraphList = PayablesGraphList(agingData: []);
      receivableList = AdvancePaidToSupplierPayablesList(agingData: []);
      supplierList = SupplierAnalysisPayablesList(supplierData: []);
      supplierCategoryList = SupplierCategoryWiseAnalysisPayablesList(
        supplierCategoryData: [],
      );
      documentList = DocumentTypeList(documentData: []);
      touchedPayables = "";
      touchedAdvancePaid = "";
      touchedSupplier = "";
      touchedSupplierType = "";
      touchedDocumentType = "";
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoadedPayables = false;
      payableGraphList = PayablesGraphList(agingData: []);
      receivableList = AdvancePaidToSupplierPayablesList(agingData: []);
      supplierList = SupplierAnalysisPayablesList(supplierData: []);
      supplierCategoryList = SupplierCategoryWiseAnalysisPayablesList(
        supplierCategoryData: [],
      );
      documentList = DocumentTypeList(documentData: []);
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

  Future<void> generatePayablesExcel(PayablesGraphList list) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Ageing Group', 'Ageing Group Total']));
      for (var monthlyData in list.agingData) {
        sheet.appendRow(
          toCellRow([monthlyData.agingGroup, monthlyData.agingGroupTotal]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('payables_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/payables_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generatePayablesPDF(PayablesGraphList list) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Payables',
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
                for (var data in payableGraphList.agingData)
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
                        data.agingGroupTotal.toString(),
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
        final file = File('$storageDir/payables.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateAdvanceExcel(
    AdvancePaidToSupplierPayablesList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Ageing Group', 'Ageing Group Total']));
      for (var monthlyData in list.agingData) {
        sheet.appendRow(
          toCellRow([monthlyData.agingGroup, monthlyData.agingGroupTotal]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('advance_paid_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/advance_paid_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateAdvancePDF(
    AdvancePaidToSupplierPayablesList list,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Advance Paid To Supplier',
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
                for (var data in receivableList.agingData)
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
                        data.agingGroupTotal.toString(),
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
        final file = File('$storageDir/advance_paid.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierExcel(SupplierAnalysisPayablesList list) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Supplier Name', 'Amount']));
      for (var monthlyData in list.supplierData) {
        sheet.appendRow(
          toCellRow([monthlyData.supplierName, monthlyData.balance]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('supplier_analysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/supplier_analysis.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierPDF(SupplierAnalysisPayablesList list) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier Analysis',
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
                      'Supplier Name',
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
                for (var data in supplierList.supplierData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.supplierName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.balance.toString(),
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
        final file = File('$storageDir/supplier_analysis.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierCategoryExcel(
    SupplierCategoryWiseAnalysisPayablesList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Supplier Category', 'Amount']));
      for (var monthlyData in list.supplierCategoryData) {
        sheet.appendRow(
          toCellRow([monthlyData.supplierCategoryName, monthlyData.balance]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('supplier_category_analysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/supplier_category_analysis.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierCategoryPDF(
    SupplierCategoryWiseAnalysisPayablesList list,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier Category Analysis',
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
                      'Supplier Category',
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
                for (var data in supplierCategoryList.supplierCategoryData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.supplierCategoryName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.balance.toString(),
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
        final file = File('$storageDir/supplier_category_analysis.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateDocumentTypeExcel(DocumentTypeList list) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Document Type', 'Amount']));
      for (var monthlyData in list.documentData) {
        sheet.appendRow(
          toCellRow([monthlyData.documentType, monthlyData.balance]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('document_type.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/document_type.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateDocumentTypePDF(DocumentTypeList list) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Document Type',
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
                      'Document Type',
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
                for (var data in documentList.documentData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.documentType,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.balance.toString(),
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
        final file = File('$storageDir/supplier_category_analysis.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void toggleCheckbox() {
    setState(() {
      payableDouble = 0;
      advanceDouble = 0;
      chartDataLoadedPayables = false;
      loadData("");
      // selectedCheckbox = index;
    });
  }

  Future<void> filterDateFunction() async {
    setState(() {
      chartDataLoadedPayables = false;
    });
    payablesList = payablesListMaster;
    _dateFilterTarget();
    await _loadPayablesData("", "", "", "", "", "");
    await _loadAdvancePaidData("", "", "", "", "", "");
    await _loadSupplierAnalysis("", "", "", "", "", "");
    await _loadVendorPaymentProjection();
    await _loadSupplierCategoryAnalysis("", "", "", "", "", "");
    await _loadDocumentTypeAnalysis("", "", "", "", "", "");
    await _loadbpGroup("", "", "", "", "", "");
    await _loadAdvanceVendors();
    await _loadCapitalVendors();
    await _loadFixedExpenses();
    setState(() {
      notDue = 0;
      overDue = 0;
      netPayable = 0;

      payableDouble = 0;
      advanceDouble = 0;
      chartDataLoadedPayables = false;
      List<String> trueCategoryOptions = (allCategoriesState['Category'] ?? {})
          .entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      List<String> trueSupplierOptions = (allCategoriesState['Supplier'] ?? {})
          .entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      List<PayablesList> filteredList = [];

      if (trueCategoryOptions.isNotEmpty) {
        filteredList = payablesList
            .where((person) => trueCategoryOptions.contains(person.vendorGroup))
            .toList();
        payablesList = filteredList;
      }

      if (trueSupplierOptions.isNotEmpty) {
        filteredList = payablesList
            .where((person) => trueSupplierOptions.contains(person.vendorName))
            .toList();
        payablesList = filteredList;
      }

      chartDataLoadedPayables = true;

      filterOptions = [listOfCategory, listOfSupplier, []];

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
      // selectedCheckbox = index;

      double payableSum = 0;
      double advanceSum = 0;
      double payablesSum = 0;
      List<PayablesList> currentMonthTarget = payablesList.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
        return dueon.isAtMost(currentMonthToDate!) &&
            target.ageingBrackets != "Future";
      }).toList();

      for (var target in currentMonthTarget.toList()) {
        double balance = double.tryParse(target.balance) ?? 0;
        double balanceAbs = balance;
        payableSum += balanceAbs;
        if (balance > 0) {
          advanceSum += balance;
        }
        if (balance < 0) {
          payablesSum += balance;
        }
      }

      payableStr = formatAmount(payablesSum.abs());

      advanceStr = formatAmount(advanceSum);
      // payableStr = formatAmount(payableSum);
      payableAdvanceStr = formatAmount(payableSum.abs());
      payableAdvancePercentage =
          double.tryParse(
            ((advanceSum.abs() / (payableSum.abs())) * 100).toStringAsFixed(0),
          )?.ceil() ??
          0;
      if (payableAdvancePercentage > 100) {
        payableAdvancePercentage = 100;
      }

      var notOverDue = payablesList;
      for (var target in notOverDue.toList()) {
        String future = target.ageingBrackets;
        if (future == 'Future') {
          // notDue += balance;
        }
      }

      double netPayableSum = 0;

      for (var target in payablesList.toList()) {
        // overDueSum += balance;
        double balance = double.tryParse(target.balance) ?? 0;
        String future = target.ageingBrackets;
        if (balance < 0) {
          netPayableSum += balance;
        }
        if (future != "Future" && balance < 0) {
          overDue += balance;
        }
        if (future == "Future" && balance < 0) {
          notDue += balance;
        }
      }

      netPayable = /* notDue +*/ netPayableSum;
      netPayableStr = "";
      netPayableStr = formatAmount(netPayable.abs());
      // overDue = overDueSum;
      overDueStr = formatAmount(overDue.abs());
      notDueStr = formatAmount(notDue.abs());

      if (overDue == 0 || netPayable == 0) {
        netPayablePercentage = 0;
      } else {
        netPayablePercentage =
            double.tryParse(
              ((overDue / (netPayable)) * 100).toStringAsFixed(2),
            )?.ceil() ??
            0;
      }

      if (netPayablePercentage > 100) {
        netPayablePercentage = 100;
      }
      setState(() {
        chartDataLoadedPayables = true;
      });
    });
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

  Future<void> generateVendorPaymentProjectionReport() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow([
        'Vendor Code',
        'Vendor Name',
        'Balance Due',
        '0-30',
        '31-60',
        '61-90',
        '91-180',
        '180+',
        'Commitment',
        'Actual Paid',
      ]),
    );

    for (var vendorData in vendorProjectionList.vendorData) {
      sheet.appendRow(
        toCellRow([
          vendorData.vendorCode,
          vendorData.vendorName,
          vendorData.balanceDue,
          vendorData.a0to30,
          vendorData.a31to60,
          vendorData.a61to90,
          vendorData.a90to180,
          vendorData.a180above,
          vendorData.commitment,
          vendorData.actualPayable,
        ]),
      );
    }

    setState(() {
      // YtdSalesBarChartData = true;
    });

    if (kIsWeb) {
      // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');

      final excelBytes = excel.encode()!;
      saveAndOpenExcel('VendorPaymentProjection.xlsx', excelBytes);

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
      final file = File('$storageDir/vendorsPaymentProjection.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> generatebgGroup() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow([
        'Payables',
        'Commitment',
        'Actual Paid',
        'Deficit(-)/Surplus(+)',
      ]),
    );

    for (var vendorData in bpGroupList.supplierCategoryData) {
      sheet.appendRow(
        toCellRow([
          vendorData.supplierCategoryName,
          vendorData.commitment,
          vendorData.actualPaid,
          vendorData.actualPaid! - vendorData.commitment!,
        ]),
      );
    }

    setState(() {
      // YtdSalesBarChartData = true;
    });

    if (kIsWeb) {
      // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');

      final excelBytes = excel.encode()!;
      saveAndOpenExcel('bpGroupExcel.xlsx', excelBytes);

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
      final file = File('$storageDir/bpGroupExcel.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> generateFixedExpenses() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow([
        'Particulars',
        // 'Balance',
        'Target',
        'Actual Paid',
      ]),
    );

    for (var vendorData in fixedExpensesList.supplierCategoryData) {
      sheet.appendRow(
        toCellRow([
          vendorData.supplierCategoryName,
          // vendorData.balance.toStringAsFixed(0),
          vendorData.commitment!.toStringAsFixed(0),
          vendorData.actualPaid!.toStringAsFixed(0),
        ]),
      );
    }

    setState(() {
      // YtdSalesBarChartData = true;
    });

    if (kIsWeb) {
      // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');

      final excelBytes = excel.encode()!;
      saveAndOpenExcel('fixedExpenses.xlsx', excelBytes);

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
      final file = File('$storageDir/fixedExpenses.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> generateAdvanceVendors() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(toCellRow(['Vendor Name', 'Balance Due', 'Actual Paid']));

    for (var vendorData in advanceVendorList.supplierData) {
      sheet.appendRow(
        toCellRow([
          vendorData.supplierName,
          vendorData.balance,
          vendorData.actualPaid,
        ]),
      );
    }

    setState(() {
      // YtdSalesBarChartData = true;
    });

    if (kIsWeb) {
      // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');

      final excelBytes = excel.encode()!;
      saveAndOpenExcel('advanceVendors.xlsx', excelBytes);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/advanceVendors.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> generateCapitalVendors() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow([
        'Vendor Code',
        'Vendor Name',
        'Balance Due',
        '0-30',
        '31-60',
        '61-90',
        '91-180',
        '180+',
        'Commitment',
        'Actual Paid',
      ]),
    );

    for (var vendorData in capitalVendorsList.vendorData) {
      sheet.appendRow(
        toCellRow([
          vendorData.vendorCode,
          vendorData.vendorName,
          vendorData.balanceDue,
          vendorData.a0to30,
          vendorData.a31to60,
          vendorData.a61to90,
          vendorData.a90to180,
          vendorData.a180above,
          vendorData.commitment,
          vendorData.actualPayable,
        ]),
      );
    }

    setState(() {
      // YtdSalesBarChartData = true;
    });

    if (kIsWeb) {
      // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');

      final excelBytes = excel.encode()!;
      saveAndOpenExcel('capitalVendors.xlsx', excelBytes);

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
      final file = File('$storageDir/capitalVendors.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
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

  @override
  void initState() {
    super.initState();

    filterOptions = [listOfCategory, listOfSupplier, []];

    selectedFinanceReceivablesOptions = filterOptions
        .map((options) => List<bool>.filled(options.length, false))
        .toList();

    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
  }

  @override
  Widget build(BuildContext context) {
    DateTime currentDate = DateTime.now();
    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
    return chartDataLoadedPayables == true
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
                                "${formatDateString(fiscalYearStartDate!)} - ${formatDateString(currentDate)}",
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
                                  generatebgGroup();
                                },
                                child: const Row(
                                  children: [Text("Download BP Group Summary")],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  generateAdvanceVendors();
                                },
                                child: const Row(
                                  children: [
                                    Text("Download Advance Vendors Summary"),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  generateCapitalVendors();
                                },
                                child: const Row(
                                  children: [
                                    Text("Download Capital Vendors Summary"),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  generateFixedExpenses();
                                },
                                child: const Row(
                                  children: [
                                    Text("Download Fixed Expenses Summary"),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Visibility(
                  visible: getSelectedFiltersText(allCategoriesState) != "",
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        "Selected Filters: ${getSelectedFiltersText(allCategoriesState)}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, right: 6.0),
                      child: CircularPercentIndicator(
                        arcType: ArcType.HALF,
                        radius: 75.0,
                        lineWidth: 30.0,
                        animation: true,
                        percent: netPayablePercentage / 100,
                        curve: Curves.linear,
                        circularStrokeCap: CircularStrokeCap.butt,
                        progressColor: const Color(0xFF2CA9DF),
                        arcBackgroundColor: const Color(0xFF97D7F3),
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 70),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Payables: $netPayableStr",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 10,
                                  width: 10,
                                  color: const Color(0xFF97D7F3),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "OverDue $overDueStr",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 10,
                                  width: 10,
                                  color: const Color(0xFF2CA9DF),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Not Due $notDueStr",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, right: 6.0),
                      child: CircularPercentIndicator(
                        arcType: ArcType.HALF,
                        radius: 75.0,
                        lineWidth: 30.0,
                        animation: true,
                        percent: payableAdvancePercentage / 100,
                        curve: Curves.linear,
                        circularStrokeCap: CircularStrokeCap.butt,
                        progressColor: const Color(0xFF2CA9DF),
                        arcBackgroundColor: const Color(0xFF97D7F3),
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 70),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Net Payables: $payableAdvanceStr",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 10,
                                  width: 10,
                                  color: const Color(0xFF2CA9DF),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Advance $advanceStr",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 10,
                                  width: 10,
                                  color: const Color(0xFF97D7F3),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Payable $payableStr",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: Center(
                //     child: ElevatedButton(
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: const Color(0xff2ca9df),
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(5.0),
                //         ),
                //       ),
                //       onPressed: () {
                //         generateVendorPaymentProjectionReport();
                //       },
                //       child: const SizedBox(
                //         width: 400,
                //         child: Center(
                //           child: Text(
                //             "Download Vendor Payment Projection",
                //             style: TextStyle(fontSize: 14, color: Colors.white),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
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
                          "Vendor Payment Projection",
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
                                    generateVendorPaymentProjectionReport();
                                  });
                                },
                                child: const Text(
                                  "Download Vendor Payment Projection",
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generatePayablesExcel(payableGraphList);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generatePayablesPDF(payableGraphList);
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
                  child: _payables(),
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
                          "BP Group Summary",
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
                                    generatebgGroup();
                                  });
                                },
                                child: const Text("Download Excel"),
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
                  child: _bpGroup(),
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
                          "Advance Vendors",
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
                                    generateAdvanceVendors();
                                  });
                                },
                                child: const Text("Download Excel"),
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
                  child: _advanceVendors(),
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
                          "Capital Vendors",
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
                                    generateCapitalVendors();
                                  });
                                },
                                child: const Text("Download Excel"),
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
                  child: _capitalVendors(),
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
                          "Fixed Expenses",
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
                                    generateFixedExpenses();
                                  });
                                },
                                child: const Text("Download Excel"),
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
                  child: _fixedExpenses(),
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
                          "Advance Paid to Supplier",
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
                                    generateAdvanceExcel(receivableList);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateAdvancePDF(receivableList);
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
                  child: _advancePaidToSupplier(),
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
                          "Supplier Analysis",
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
                                    generateSupplierExcel(supplierList);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierPDF(supplierList);
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
                  child: _supplierAnalysis(),
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
                          "Supplier Category Wise Analysis",
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
                                    generateSupplierCategoryExcel(
                                      supplierCategoryList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierCategoryPDF(
                                      supplierCategoryList,
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
                  child: _supplierCategoryWiseAnalysis(),
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
                          "Document Type",
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
                                    generateDocumentTypeExcel(documentList);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateDocumentTypePDF(documentList);
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
                  child: _documentTypeAnalysis(),
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

  Widget _payables() {
    final screenWidth = MediaQuery.of(context).size.width;

    final amounts = payableGraphList.agingData
        .map((e) => e.agingGroupTotal)
        .whereType<double>()
        .toList();

    final hasPositive = amounts.any((a) => a > 0);
    final hasNegative = amounts.any((a) => a < 0);

    double chartMinY = 0;
    double chartMaxY = 0;

    if (hasPositive && hasNegative) {
      // Both positive and negative
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
        width: screenWidth,
        child: BarChart(
          BarChartData(
            maxY: chartMaxY,
            minY: chartMinY,
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesPayables,
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
            barGroups: _payablesChartData(payableGraphList.agingData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedPayables = touchedPayables == ""
                          ? payableGraphList
                                .agingData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .agingGroup
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedPayables,
                        touchedAdvancePaid,
                        touchedSupplier,
                        touchedSupplierType,
                        touchedDocumentType,
                        touchedBPgroup,
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
                            '${payableGraphList.agingData[0].agingGroup} :'
                            ' ${(payableGraphList.agingData[0].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${payableGraphList.agingData[1].agingGroup} '
                            ': ${(payableGraphList.agingData[1].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${payableGraphList.agingData[2].agingGroup} '
                            ': ${(payableGraphList.agingData[2].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${payableGraphList.agingData[3].agingGroup} '
                            ': ${(payableGraphList.agingData[3].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${payableGraphList.agingData[4].agingGroup} '
                            ': ${(payableGraphList.agingData[4].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${payableGraphList.agingData[5].agingGroup} '
                            ': ${(payableGraphList.agingData[5].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Total'
                            ': ${((payableGraphList.agingData[5].agingGroupTotal + payableGraphList.agingData[4].agingGroupTotal + payableGraphList.agingData[3].agingGroupTotal + payableGraphList.agingData[2].agingGroupTotal + payableGraphList.agingData[1].agingGroupTotal + payableGraphList.agingData[0].agingGroupTotal) / 100000).toStringAsFixed(2)} L',
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

  Widget _advancePaidToSupplier() {
    final screenWidth = MediaQuery.of(context).size.width;

    final amounts = receivableList.agingData
        .map((e) => e.agingGroupTotal)
        .whereType<double>()
        .toList();

    final hasPositive = amounts.any((a) => a > 0);
    final hasNegative = amounts.any((a) => a < 0);

    double chartMinY = 0;
    double chartMaxY = 0;

    if (hasPositive && hasNegative) {
      // Both positive and negative
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
        width: screenWidth,
        child: BarChart(
          BarChartData(
            maxY: chartMaxY,
            minY: chartMinY,
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesAdvancePaid,
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
            barGroups: _advancePaidChartData(receivableList.agingData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedAdvancePaid = touchedAdvancePaid == ""
                          ? receivableList
                                .agingData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .agingGroup
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedPayables,
                        touchedAdvancePaid,
                        touchedSupplier,
                        touchedSupplierType,
                        touchedDocumentType,
                        touchedBPgroup,
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
                            '${receivableList.agingData[0].agingGroup} :'
                            ' ${(receivableList.agingData[0].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivableList.agingData[1].agingGroup} '
                            ': ${(receivableList.agingData[1].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivableList.agingData[2].agingGroup} '
                            ': ${(receivableList.agingData[2].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivableList.agingData[3].agingGroup} '
                            ': ${(receivableList.agingData[3].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivableList.agingData[4].agingGroup} '
                            ': ${(receivableList.agingData[4].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivableList.agingData[5].agingGroup} '
                            ': ${(receivableList.agingData[5].agingGroupTotal / 100000).toStringAsFixed(2)} L\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Total'
                            ': ${((receivableList.agingData[5].agingGroupTotal + receivableList.agingData[4].agingGroupTotal + receivableList.agingData[3].agingGroupTotal + receivableList.agingData[2].agingGroupTotal + receivableList.agingData[1].agingGroupTotal + receivableList.agingData[0].agingGroupTotal) / 100000).toStringAsFixed(2)} L',
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

  Widget _supplierAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = supplierList.supplierData.length;
    if (supplierList.supplierData.length > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }

    final amounts = supplierList.supplierData
        .map((e) => e.balance)
        .whereType<double>()
        .toList();

    final hasPositive = amounts.any((a) => a > 0);
    final hasNegative = amounts.any((a) => a < 0);

    double chartMinY = 0;
    double chartMaxY = 0;

    if (hasPositive && hasNegative) {
      // Both positive and negative
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
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesSupplierAnalysis,
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
            barGroups: _supplierAnalysisChartData(supplierList.supplierData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplier = touchedSupplier == ""
                          ? supplierList
                                .supplierData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .supplierName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedPayables,
                        touchedAdvancePaid,
                        touchedSupplier,
                        touchedSupplierType,
                        touchedDocumentType,
                        touchedBPgroup,
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
                    "${supplierList.supplierData[grpIndex].supplierName}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          supplierList.supplierData[grpIndex].balance,
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
    );
  }

  Widget _supplierCategoryWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = supplierCategoryList.supplierCategoryData.length;
    if (supplierCategoryList.supplierCategoryData.length > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }

    final amounts = supplierCategoryList.supplierCategoryData
        .map((e) => e.balance)
        .whereType<double>()
        .toList();

    final hasPositive = amounts.any((a) => a > 0);
    final hasNegative = amounts.any((a) => a < 0);

    double chartMinY = 0;
    double chartMaxY = 0;

    if (hasPositive && hasNegative) {
      // Both positive and negative
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
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesSupplierCategoryAnalysis,
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
            barGroups: _supplierCategoryAnalysisChartData(
              supplierCategoryList.supplierCategoryData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplierType = touchedSupplierType == ""
                          ? supplierCategoryList
                                .supplierCategoryData[barTouchResponse
                                    .spot!
                                    .spot
                                    .x
                                    .toInt()]
                                .supplierCategoryName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedPayables,
                        touchedAdvancePaid,
                        touchedSupplier,
                        touchedSupplierType,
                        touchedDocumentType,
                        touchedBPgroup,
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
                    "${supplierCategoryList.supplierCategoryData[grpIndex].supplierCategoryName}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          supplierCategoryList
                              .supplierCategoryData[grpIndex]
                              .balance,
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
    );
  }

  Widget _documentTypeAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = documentList.documentData.length;
    if (documentList.documentData.length > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }

    final amounts = documentList.documentData
        .map((e) => e.balance)
        .whereType<double>()
        .toList();

    final hasPositive = amounts.any((a) => a > 0);
    final hasNegative = amounts.any((a) => a < 0);

    double chartMinY = 0;
    double chartMaxY = 0;

    if (hasPositive && hasNegative) {
      // Both positive and negative
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
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesDocumentType,
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
            barGroups: _documentTypeChartData(documentList.documentData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedDocumentType = touchedDocumentType == ""
                          ? documentList
                                .documentData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .documentType
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedPayables,
                        touchedAdvancePaid,
                        touchedSupplier,
                        touchedSupplierType,
                        touchedDocumentType,
                        touchedBPgroup,
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
                    "${documentList.documentData[grpIndex].documentType}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          documentList.documentData[grpIndex].balance,
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
    );
  }

  Widget _bpGroup() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = bpGroupList.supplierCategoryData.length;
    if (bpGroupList.supplierCategoryData.length > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }

    final amounts = bpGroupList.supplierCategoryData
        .map((e) => e.balance)
        .whereType<double>()
        .toList();

    final hasPositive = amounts.any((a) => a > 0);
    final hasNegative = amounts.any((a) => a < 0);

    double chartMinY = 0;
    double chartMaxY = 0;

    if (hasPositive && hasNegative) {
      // Both positive and negative
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
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesbpGroup,
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
            barGroups: _bpGroupChartData(bpGroupList.supplierCategoryData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedBPgroup = touchedBPgroup == ""
                          ? bpGroupList
                                .supplierCategoryData[barTouchResponse
                                    .spot!
                                    .spot
                                    .x
                                    .toInt()]
                                .supplierCategoryName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedPayables,
                        touchedAdvancePaid,
                        touchedSupplier,
                        touchedSupplierType,
                        touchedDocumentType,
                        touchedBPgroup,
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
                    "${bpGroupList.supplierCategoryData[grpIndex].supplierCategoryName}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          bpGroupList.supplierCategoryData[grpIndex].balance,
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
    );
  }

  Widget _advanceVendors() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = advanceVendorList.supplierData.length;
    if (advanceVendorList.supplierData.length > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? advanceVendorList.supplierData
              .map((data) => data.balance)
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
                sideTitles: _bottomTitlesAdvanceVendors,
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
            barGroups: _advanceVendorChartData(advanceVendorList.supplierData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    // if (flTouchEvent is FlTapUpEvent) {
                    //   touchedDocumentType = touchedDocumentType == ""
                    //       ? documentList
                    //           .documentData[
                    //               barTouchResponse.spot!.spot.x.toInt()]
                    //           .documentType
                    //       : "";
                    //   selectedChart = barTouchResponse.spot!.spot.x;
                    //   showDrillDownChart = true;
                    //   loadDataWithFilter(
                    //     touchedPayables,
                    //     touchedAdvancePaid,
                    //     touchedSupplier,
                    //     touchedSupplierType,
                    //     touchedDocumentType,
                    //   );
                    // }
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
                    "${advanceVendorList.supplierData[grpIndex].supplierName}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          advanceVendorList.supplierData[grpIndex].balance,
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
    );
  }

  Widget _capitalVendors() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = capitalVendorsList.vendorData.length;
    if (capitalVendorsList.vendorData.length > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }

    final amounts = capitalVendorsList.vendorData
        .map((e) => e.balanceDue)
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
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesCapitalVendors,
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
            barGroups: _capitalVendorsChartData(capitalVendorsList.vendorData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    // if (flTouchEvent is FlTapUpEvent) {
                    //   touchedDocumentType = touchedDocumentType == ""
                    //       ? documentList
                    //           .documentData[
                    //               barTouchResponse.spot!.spot.x.toInt()]
                    //           .documentType
                    //       : "";
                    //   selectedChart = barTouchResponse.spot!.spot.x;
                    //   showDrillDownChart = true;
                    //   loadDataWithFilter(
                    //     touchedPayables,
                    //     touchedAdvancePaid,
                    //     touchedSupplier,
                    //     touchedSupplierType,
                    //     touchedDocumentType,
                    //   );
                    // }
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
                    "${capitalVendorsList.vendorData[grpIndex].vendorName}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Balance Due : ${formatAmount(capitalVendorsList.vendorData[grpIndex].balanceDue)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "0-30 : ${formatAmount(capitalVendorsList.vendorData[grpIndex].a0to30)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "31-60 : ${formatAmount(capitalVendorsList.vendorData[grpIndex].a31to60)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "61-90 : ${formatAmount(capitalVendorsList.vendorData[grpIndex].a61to90)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "91-180 : ${formatAmount(capitalVendorsList.vendorData[grpIndex].a90to180)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "180+ : ${formatAmount(capitalVendorsList.vendorData[grpIndex].a180above)}",
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

  Widget _fixedExpenses() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = fixedExpensesList.supplierCategoryData.length;
    if (fixedExpensesList.supplierCategoryData.length > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? fixedExpensesList.supplierCategoryData
              .map((data) => data.balance)
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
                sideTitles: _bottomTitlesFixedExpenses,
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
            barGroups: _fixedExpensesChartData(
              fixedExpensesList.supplierCategoryData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    // if (flTouchEvent is FlTapUpEvent) {
                    //   touchedDocumentType = touchedDocumentType == ""
                    //       ? documentList
                    //           .documentData[
                    //               barTouchResponse.spot!.spot.x.toInt()]
                    //           .documentType
                    //       : "";
                    //   selectedChart = barTouchResponse.spot!.spot.x;
                    //   showDrillDownChart = true;
                    //   loadDataWithFilter(
                    //     touchedPayables,
                    //     touchedAdvancePaid,
                    //     touchedSupplier,
                    //     touchedSupplierType,
                    //     touchedDocumentType,
                    //   );
                    // }
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
                    "${fixedExpensesList.supplierCategoryData[grpIndex].supplierCategoryName}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          fixedExpensesList
                              .supplierCategoryData[grpIndex]
                              .balance,
                        ).toString(),
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
                  // Filter UI
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
                                          // ListTile(
                                          //   title: const Text("From Date"),
                                          //   subtitle: Text(fromDateFilter !=
                                          //           null
                                          //       ? "${fromDateFilter!.day}/${fromDateFilter!.month}/${fromDateFilter!.year}"
                                          //       : formatDateString(
                                          //           fiscalYearStartDate!)),
                                          //   trailing: const Icon(
                                          //       Icons.calendar_today),
                                          //   onTap: () async {
                                          //     final picked =
                                          //         await showDatePicker(
                                          //       context: context,
                                          //       initialDate: fromDateFilter ??
                                          //           DateTime.now(),
                                          //       firstDate: fiscalYearStartDate!,
                                          //       lastDate: currentDate!,
                                          //     );
                                          //     if (picked != null) {
                                          //       setState(() {
                                          //         fromDateFilter = picked;
                                          //         dateFilterFlag = true;
                                          //       });
                                          //     }
                                          //   },
                                          // ),
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

                                      savedFinanceReceivablesOptionsTemp =
                                          savedFinanceReceivablesOptions;

                                      fromFilter = false;

                                      // toggleCheckbox();
                                      loadDataFuture = filterDateFunction();
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
                                      chartDataLoadedPayables = false;
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        chartDataLoadedPayables = false;
                                        loadDataFuture = removeFilter();
                                        Navigator.pop(context);
                                        chartDataLoadedPayables = false;
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
