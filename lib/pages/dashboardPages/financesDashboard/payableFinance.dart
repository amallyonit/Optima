// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/login_screen.dart';
import '../../../classes/dashBoard.dart';
import '../../../classes/dataManager.dart';
import '../../../classes/leads.dart';
import '../../../notificationService.dart';
import '../dashboard_card_ui.dart';
import '../ReportService.dart';

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
List<PayablesList> collectionList = [];

double payableDouble = 0.0;
double payables = 0.0;
double actualAdvance = 0.0;
String payableStr = "";
double advance = 0.0;
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
AdvancePaidToSupplierPayablesList advancePaidList =
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

final List<String> categories = [
  'Category',
  'Supplier',
  'Due/Overdue',
  'Advance/Payables',
  'Date',
];

List<List<String>> filterOptions = [
  listOfCategory,
  listOfSupplier,
  ['Not Dues', 'Overdue'],
  ['Advance', 'Payables'],
  [],
];

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

final reportService = ReportService();

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

  String formatAmount(double amount) {
    final isNegative = amount < 0;
    final positiveAmount = amount.abs();
    String formatted;

    if (positiveAmount < 1000) {
      formatted = positiveAmount.toStringAsFixed(2);
    } else if (positiveAmount < 100000) {
      formatted = '${(positiveAmount / 1000).toStringAsFixed(2)} K';
    } else if (positiveAmount < 10000000) {
      formatted = '${(positiveAmount / 100000).toStringAsFixed(2)} L';
    } else {
      formatted = '${(positiveAmount / 10000000).toStringAsFixed(2)} Cr';
    }

    return isNegative ? '-$formatted' : formatted;
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
      List<AdvancePaidToSupplierPayablesData> mData = advancePaidList.agingData;
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

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
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
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );
          }
        }
      } else {
        if (!mounted) return;
        NotificationService.info(
          title: "Info",
          message: "User list not found.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(title: "Error", message: e.toString());
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

    try {
      if (!fromFilter) {
        collectionList.clear();
        payablesList.clear();
        payablesListMaster.clear();
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
              final now = DateTime.now();

              final newCollectionList = (responseJson['responseData'] as List)
                  .map((item) {
                    final obj = PayablesList.fromJson(item);

                    // Parse once
                    final postingDate = DateFormat(
                      'dd/MM/yyyy',
                    ).parse(obj.postingDate);

                    obj.postingDateParsed = postingDate;

                    final diff = postingDate.difference(now);
                    obj.overDueDayAdvance = diff.inDays.abs();

                    obj.overDueDayReceivables =
                        double.tryParse(obj.dueDays.replaceAll(' Days', '')) ??
                        0;

                    // Cache balance
                    obj.balanceParsed = double.tryParse(obj.balance) ?? 0;

                    return obj;
                  })
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
              .read<FinancePayablesCollectionBIProvider>()
              .updateCollectionList(collectionList);

          payablesList = List.from(collectionList);
          payablesListMaster = List.from(collectionList);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  Future<void> applyPayablesVariables() async {
    // Single-pass calculation
    double netPayableSum = 0;
    double overDueLocal = 0;
    double notDueLocal = 0;
    DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

    final selectedAdvancePayables =
        (allCategoriesState['Advance/Payables'] ?? {}).entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();
    final currentDateLocal = normalize(currentDate!);
    final vendorBalances = payableVendorBalances(payablesList);

    for (var target in payablesList) {
      final isAdvance = (vendorBalances[target.vendorCode] ?? 0) > 0;
      final postingDate = normalize(target.postingDateParsed);
      if (postingDate.isAfter(currentDateLocal)) continue;
      if (selectedAdvancePayables.contains('Advance') && !isAdvance) {
        continue;
      }

      if (selectedAdvancePayables.contains('Payables') && isAdvance) {
        continue;
      }
      final balance = target.balanceParsed;
      final future = target.ageingBrackets;

      if (!postingDate.isAfter(currentDateLocal)) {
        if (future != 'Future') {
          overDueLocal += balance;
        }

        netPayableSum += balance;
      }

      if (future == 'Future') {
        notDueLocal += balance;
      }
    }

    if (selectedAdvancePayables.contains('Payables')) {
      netPayableSum += actualAdvance;
      overDueLocal += actualAdvance;
    }
    if (selectedAdvancePayables.contains('Advance') && actualAdvance > 0) {
      netPayableSum = 0;
      overDueLocal = 0;
      notDueLocal = 0;
    }
    // Safe calculations

    int payableAdvancePercentageLocal = 0;

    if (payables != 0) {
      payableAdvancePercentageLocal = ((advance.abs() / payables.abs()) * 100)
          .ceil();
    }

    if (payableAdvancePercentageLocal > 100) {
      payableAdvancePercentageLocal = 100;
    }

    int netPayablePercentageLocal = 0;

    if (overDueLocal != 0 && netPayableSum != 0) {
      netPayablePercentageLocal = ((overDueLocal / netPayableSum) * 100).ceil();
    }

    if (netPayablePercentageLocal > 100) {
      netPayablePercentageLocal = 100;
    }

    // FINAL UI UPDATE
    if (mounted) {
      setState(() {
        payableStr = formatAmount(payables.abs());
        advanceStr = formatAmount(advance);
        payableAdvanceStr = formatAmount(payables.abs() - advance);

        payableAdvancePercentage = payableAdvancePercentageLocal;

        netPayable = netPayableSum;
        netPayableStr = formatAmount(netPayable.abs());

        overDue = overDueLocal;
        notDue = notDueLocal;

        overDueStr = formatAmount(overDue.abs());
        notDueStr = formatAmount(notDue.abs());

        netPayablePercentage = netPayablePercentageLocal;
      });
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
      if (!mounted) return;
      NotificationService.error(title: "Error", message: e.toString());
    }
  }

  Future<void> _loadModeOfPayment(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<ModeOfPaymentList> modeOfPaymentList = [];
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
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<ModeOfPaymentList> newList =
                (responseJson['responseData'] as List).map((item) {
                  final obj = ModeOfPaymentList.fromJson(item);
                  final postingDate = DateFormat(
                    'dd/MM/yyyy',
                  ).parse(obj.postingDate);
                  obj.postingDateParsed = postingDate;
                  return obj;
                }).toList();

            modeOfPaymentList.addAll(newList);
            fetchedCount = newList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        context.read<ActualPayableProvider>().updateTargetList(
          modeOfPaymentList,
        );
        modeOfPayment = modeOfPaymentList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(title: "Error", message: e.toString());
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

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sales target details not found.')),
          );
        }
        return;
      }

      final Map<String, dynamic> responseJson = jsonDecode(response.body);

      final data = responseJson['responseData'];

      // Handle empty or invalid data safely
      if (data == null || data is! List || data.isEmpty) {
        final error = responseJson["Error"]?.toString() ?? "Unknown error";

        if (error == "Invalid or Expired Token") {
          if (!mounted) return;
          NotificationService.warning(
            title: "Security Alert",
            message: "Invalid or Expired Token.",
          );
          navigateToLoginScreen();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          }
        }
        return;
      }

      // Parse once
      final List<SalesTargetList> newSalesTargetList = (data)
          .map((item) => SalesTargetList.fromJson(item))
          .toList();

      // UI update (lightweight only)
      setState(() {
        context.read<PayableSalesTargetProvider>().updateSalesTargetList(
          newSalesTargetList,
        );

        salesTarget = newSalesTargetList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SAP Server down, Please try again after some time.'),
          ),
        );
      }
    }
  }

  AgingSummary summarizeCollectionTargets(
    Iterable<PayablesList> collectionTargetList,
  ) {
    AgingSummary summary = AgingSummary();
    double balance = 0;
    var overDueDays = 0;
    for (var element in collectionTargetList) {
      overDueDays = int.tryParse(element.dueDays.replaceAll(' Days', '')) ?? 0;
      balance = double.tryParse(element.balance) ?? 0;
      if (balance < 0) {}
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

      final vendorIsAdvance = isAdvanceVendor(t.vendorCode);
      if (fAdvance.isNotEmpty && !vendorIsAdvance) {
        continue;
      }
      if (fPayable.isNotEmpty && vendorIsAdvance) {
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

  Future<void> _loadVendorPaymentProjection() async {
    final df = DateFormat('dd/MM/yyyy');

    final DateTime? effectiveCurrentMonthToDate = currentMonthToDate;

    final Map<String, Map<String, dynamic>> aggregatedPayableData = {};

    for (final payableItem in payablesList) {
      final postingDate = df.parse(payableItem.postingDate);
      if (!postingDate.isAtMost(effectiveCurrentMonthToDate!)) continue;

      final vendorCode = payableItem.vendorCode;
      final vendorName = payableItem.vendorName;

      aggregatedPayableData.putIfAbsent(
        vendorCode,
        () => {
          'vendorCode': vendorCode,
          'vendorName': vendorName,
          'totalPayable': 0.0,
          'balance': 0.0,
          'future': 0.0,
          'a0to30': 0.0,
          'a31to60': 0.0,
          'a61to90': 0.0,
          'a90to180': 0.0,
          'a180above': 0.0,
          'commitment': 0.0,
        },
      );

      final vendorData = aggregatedPayableData[vendorCode]!;

      vendorData['totalPayable'] =
          (vendorData['totalPayable'] as double) +
          (double.tryParse(payableItem.balance) ?? 0.0) * -1;
      final dueOn = df.parse(payableItem.dueon);
      if (dueOn.isAtMost(effectiveCurrentMonthToDate)) {
        final balance = (double.tryParse(payableItem.balance) ?? 0.0) * -1;

        switch (payableItem.ageingBrackets) {
          case "0-30 Days":
            vendorData['a0to30'] = (vendorData['a0to30'] as double) + balance;

            vendorData['balance'] = (vendorData['balance'] as double) + balance;
            break;

          case "31-60 Days":
            vendorData['a31to60'] = (vendorData['a31to60'] as double) + balance;

            vendorData['balance'] = (vendorData['balance'] as double) + balance;
            break;

          case "61-90 Days":
            vendorData['a61to90'] = (vendorData['a61to90'] as double) + balance;

            vendorData['balance'] = (vendorData['balance'] as double) + balance;
            break;

          case "91-180 Days":
            vendorData['a90to180'] =
                (vendorData['a90to180'] as double) + balance;

            vendorData['balance'] = (vendorData['balance'] as double) + balance;
            break;

          case "Future":
            vendorData['future'] = (vendorData['future'] as double) + balance;

            vendorData['balance'] = (vendorData['balance'] as double) + balance;
            break;

          default:
            vendorData['a180above'] =
                (vendorData['a180above'] as double) + balance;

            vendorData['balance'] = (vendorData['balance'] as double) + balance;
        }
      }

      vendorData['commitment'] =
          (vendorData['commitment'] as double) +
          (double.tryParse(payableItem.commitment) ?? 0.0);
    }

    final Map<String, double> actualPayableByVendorName = {};
    for (final paymentEntry in modeOfPayment.where(
      (entry) => entry.vendorCode.toLowerCase().startsWith('v'),
    )) {
      final dueOn = df.parse(paymentEntry.postingDate);

      if (dueOn.isAtMost(effectiveCurrentMonthToDate!)) {
        actualPayableByVendorName.update(
          paymentEntry.vendorCode,
          (value) => value + (double.tryParse(paymentEntry.total) ?? 0.0),
          ifAbsent: () => (double.tryParse(paymentEntry.total) ?? 0.0),
        );
      }
    }

    final Map<String, double> currentMonthPayableByVendorName = {};
    for (final paymentEntry in modeOfPayment.where(
      (entry) => entry.vendorCode.toLowerCase().startsWith('v'),
    )) {
      final dueOn = df.parse(paymentEntry.postingDate);

      if (dueOn.isAtLeast(currentMonthFromDate!) &&
          dueOn.isAtMost(currentMonthToDate!)) {
        currentMonthPayableByVendorName.update(
          paymentEntry.vendorCode,
          (value) => value + (double.tryParse(paymentEntry.total) ?? 0.0),
          ifAbsent: () => (double.tryParse(paymentEntry.total) ?? 0.0),
        );
      }
    }

    final List<VendorsPaymentProjectionData> vendorWiseData = [];
    for (final entry in aggregatedPayableData.values) {
      final vendorName = entry['vendorName'] as String;
      final vendorCode = entry['vendorCode'] as String;
      final totalPayable = entry['totalPayable'] as double;
      final balanceDue = entry['balance'] as double;
      final future = entry['future'] as double;
      final a0to30 = entry['a0to30'] as double;
      final a31to60 = entry['a31to60'] as double;
      final a61to90 = entry['a61to90'] as double;
      final a90to180 = entry['a90to180'] as double;
      final a180above = entry['a180above'] as double;
      final commitment = entry['commitment'] as double;

      final actualPayable = actualPayableByVendorName[vendorCode] ?? 0.0;
      final currentMonthPayable =
          currentMonthPayableByVendorName[vendorCode] ?? 0.0;

      vendorWiseData.add(
        VendorsPaymentProjectionData(
          vendorName: vendorName,
          vendorCode: vendorCode,
          totalPayable: totalPayable,
          balanceDue: balanceDue,
          future: future,
          a0to30: a0to30,
          a31to60: a31to60,
          a61to90: a61to90,
          a90to180: a90to180,
          a180above: a180above,
          commitment: commitment,
          currentMonthPayable: currentMonthPayable,
          actualPayable: actualPayable,
          overDue: 0.0,
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

    final DateTime? effectiveCurrentMonthToDate = currentMonthToDate;

    // ---------- Step 1: Filter rows ----------
    final filteredList = payablesList.where((t) {
      final dueOn = df.parse(t.postingDate);
      if (!dueOn.isAtMost(effectiveCurrentMonthToDate!)) return false;

      final tVendorNameLower = t.vendorName.toLowerCase();
      final tVendorGroupLower = t.vendorGroup.toLowerCase();
      final tDocumentTypeLower = t.documentType.toLowerCase();
      final tBpSubGroupLower = t.bpSubGroup.toLowerCase();

      final vendorIsAdvance = isAdvanceVendor(t.vendorCode);
      if (fAdvance.isNotEmpty && !vendorIsAdvance) {
        return false;
      }
      if (fPayable.isNotEmpty && vendorIsAdvance) {
        return false;
      }
      // final tAgeingBracketsLower = t.ageingBrackets.toLowerCase();
      // if (fPayable.isNotEmpty && !tAgeingBracketsLower.contains(fPayable)) {
      //   return false;
      // }
      // if (fAdvance.isNotEmpty && !tAgeingBracketsLower.contains(fAdvance)) {
      //   return false;
      // }

      if (fSupplier.isNotEmpty && tVendorNameLower != fSupplier) return false;
      if (fSupCat.isNotEmpty && tVendorGroupLower != fSupCat) return false;
      if (fDocType.isNotEmpty && tDocumentTypeLower != fDocType) return false;
      if (fBpGroup.isNotEmpty && tBpSubGroupLower != fBpGroup) return false;

      return true;
    }).toList();

    // ---------- Step 2: Group by vendor ----------
    final Map<String, List<dynamic>> vendorMap = {};

    for (var t in filteredList) {
      vendorMap.putIfAbsent(t.vendorCode, () => []).add(t);
    }

    // ---------- Step 3: Initialize buckets ----------
    final List<double> bucketSums = List<double>.filled(6, 0.0);

    int getBucketIndex(String bracket) {
      switch (bracket) {
        case "Future":
          return 0;
        case "0-30 Days":
          return 1;
        case "31-60 Days":
          return 2;
        case "61-90 Days":
          return 3;
        case "91-180 Days":
          return 4;
        default:
          return 5;
      }
    }

    // ---------- Step 4: Apply supplier-level logic ----------
    for (var entry in vendorMap.entries) {
      final rows = entry.value;

      double totalBalance = 0;

      // Net per vendor (same as _loadSupplierAnalysis)
      for (var r in rows) {
        totalBalance += double.tryParse(r.balance) ?? 0;
      }

      // Only ADVANCE (positive)
      if (totalBalance <= 0) continue;

      // ---------- Step 5: Distribute ----------
      for (var r in rows) {
        final idx = getBucketIndex(r.ageingBrackets);
        final amt = double.tryParse(r.balance) ?? 0;

        bucketSums[idx] += amt;
      }
    }

    // ---------- Step 6: Total ----------
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

    advancePaidList = AdvancePaidToSupplierPayablesList(agingData: data);
  }

  Future<void> _loadSupplierAnalysis(
    String payable,
    String advancePaid,
    String supplier,
    String supplierCategory,
    String documentType,
    String bpGroup,
  ) async {
    if (!mounted) return;
    setState(() {
      advance = 0;
      payables = 0;
    });

    double tmpAdvance = 0;
    double tmpPayables = 0;

    final fSupplier = supplier.toLowerCase();
    final fSupCat = supplierCategory.toLowerCase();
    final fDocType = documentType.toLowerCase();
    final fBpGroup = bpGroup.toLowerCase();

    final df = DateFormat('dd/MM/yyyy');

    final Map<String, double> balanceByVendor = {};
    final Map<String, String> nameByVendor = {};
    final Map<String, double> netPayablesByVendor = {};
    final DateTime? effectiveCurrentMonthToDate = currentMonthToDate;

    for (final t in payablesList) {
      final dueOn = df.parse(t.postingDate);
      if (!dueOn.isAtMost(effectiveCurrentMonthToDate!)) {
        continue;
      }

      final tVendorNameLower = t.vendorName.toLowerCase();
      final tVendorGroupLower = t.vendorGroup.toLowerCase();
      final tDocumentTypeLower = t.documentType.toLowerCase();
      final tBpSubGroupLower = t.bpSubGroup.toLowerCase();

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
      final future = t.ageingBrackets;
      if (future != "Future") {
        netPayablesByVendor.update(
          code,
          (value) => value + amt,
          ifAbsent: () => amt,
        );
      }
      balanceByVendor.update(code, (value) => value + amt, ifAbsent: () => amt);
      nameByVendor[code] = t.vendorName;
    }

    final List<SupplierAnalysisPayablesData> customerWiseDataList = [];

    final selectedAdvancePayables =
        (allCategoriesState['Advance/Payables'] ?? {}).entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

    balanceByVendor.forEach((code, sum) {
      customerWiseDataList.add(
        SupplierAnalysisPayablesData(
          supplierName: nameByVendor[code]!,
          balance: sum * -1,
          overDue: null,
        ),
      );
      if (selectedAdvancePayables.isEmpty) {
        if (sum > 0) {
          tmpAdvance += sum;
        }
        tmpPayables += netPayablesByVendor[code] ?? 0.0;
      } else {
        if (selectedAdvancePayables.contains('Advance')) {
          if (sum > 0) {
            tmpAdvance += sum;
          }
        } else {
          tmpPayables += netPayablesByVendor[code] ?? 0.0;
        }
      }
    });
    if (selectedAdvancePayables.contains('Payables')) {
      tmpPayables = tmpPayables + actualAdvance;
    }
    customerWiseDataList.sort((a, b) => b.balance.compareTo(a.balance));

    supplierList = SupplierAnalysisPayablesList(
      supplierData: customerWiseDataList,
    );

    if (listOfSupplier.isEmpty) {
      listOfSupplier = customerWiseDataList.map((e) => e.supplierName).toList();
    }
    setState(() {
      advance = tmpAdvance;
      payables = tmpPayables;
      if (selectedAdvancePayables.isEmpty) {
        actualAdvance = tmpAdvance;
      }
    });
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

      final targetVendorNameLower = target.vendorName.toLowerCase();
      final targetVendorGroupLower = target.vendorGroup.toLowerCase();
      final targetDocumentTypeLower = target.documentType.toLowerCase();
      final targetBpSubGroupLower = target.bpSubGroup.toLowerCase();

      final vendorIsAdvance = isAdvanceVendor(target.vendorCode);
      if (fAdvance.isNotEmpty && !vendorIsAdvance) {
        continue;
      }
      if (fPayable.isNotEmpty && vendorIsAdvance) {
        continue;
      }

      // final tAgeingBracketsLower = target.ageingBrackets.toLowerCase();
      // if (fPayable.isNotEmpty && !tAgeingBracketsLower.contains(fPayable)) {
      //   continue;
      // }
      // if (fAdvance.isNotEmpty && !tAgeingBracketsLower.contains(fAdvance)) {
      //   continue;
      // }

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

      final vendorIsAdvance = isAdvanceVendor(t.vendorCode);
      if (fAdvance.isNotEmpty && !vendorIsAdvance) {
        continue;
      }
      if (fPayable.isNotEmpty && vendorIsAdvance) {
        continue;
      }

      // final tAgeingBracketsLower = t.ageingBrackets.toLowerCase();
      // if (fPayable.isNotEmpty && !tAgeingBracketsLower.contains(fPayable)) {
      //   continue;
      // }
      // if (fAdvance.isNotEmpty && !tAgeingBracketsLower.contains(fAdvance)) {
      //   continue;
      // }

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

  Future<void> _loadBpGroup(
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

      final tVendorNameLower = t.vendorName.toLowerCase();
      final tVendorGroupLower = t.vendorGroup.toLowerCase();
      final tDocumentTypeLower = t.documentType.toLowerCase();
      final tBpSubGroupLower = t.bpSubGroup.toLowerCase();

      final vendorIsAdvance = isAdvanceVendor(t.vendorCode);
      if (fAdvance.isNotEmpty && !vendorIsAdvance) {
        continue;
      }
      if (fPayable.isNotEmpty && vendorIsAdvance) {
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

  Future<void> _loadAdvanceVendors() async {
    List<SupplierAnalysisPayablesData> customerWiseDataList = [];

    var customerTargetList = const Iterable.empty();
    var currentMonthActualPayable = const Iterable.empty();
    var currentMonthPaid = const Iterable.empty();

    String vendorCode = "";
    String vendorName = "";

    customerTargetList = payablesList.where((target) {
      return target.postingDateParsed.isAtMost(currentMonthToDate!) &&
          target.bpSubGroup == "Advance Vendors";
    });

    currentMonthActualPayable = modeOfPayment.where((target) {
      return target.postingDateParsed.isAtMost(currentMonthToDate!);
    });

    currentMonthPaid = modeOfPayment.where((target) {
      return target.postingDateParsed.isAtLeast(currentMonthFromDate!) &&
          target.postingDateParsed.isAtMost(currentMonthToDate!);
    });

    Set<String> processedVendorCodes = {};

    for (var customer in customerTargetList.toList()) {
      if (processedVendorCodes.contains(customer.vendorCode)) {
        continue;
      }

      vendorCode = customer.vendorCode;
      vendorName = customer.vendorName;

      double balance = 0.0;
      double overdue = 0.0;

      final vendorRows = customerTargetList.where(
        (e) => e.vendorCode == vendorCode,
      );

      for (final sales in vendorRows) {
        final balanceValue = (double.tryParse(sales.balance) ?? 0.0).abs();

        /// Total Balance
        balance += balanceValue;

        /// Overdue Balance
        if (sales.ageingBrackets != "Future") {
          overdue += balanceValue;
        }
      }

      double actualPayable = currentMonthActualPayable
          .where((entry) => entry.vendorName == vendorName)
          .fold(
            0.0,
            (sum, entry) => sum + (double.tryParse(entry.total) ?? 0.0),
          );

      double currentMthPaid = currentMonthPaid
          .where((entry) => entry.vendorName == vendorName)
          .fold(
            0.0,
            (sum, entry) => sum + (double.tryParse(entry.total) ?? 0.0),
          );

      customerWiseDataList.add(
        SupplierAnalysisPayablesData(
          supplierName: vendorName,
          balance: balance,
          overDue: overdue,
          actualPaid: actualPayable,
          currentMonthPaid: currentMthPaid,
        ),
      );

      processedVendorCodes.add(vendorCode);
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
    var currentMonthPaid = const Iterable.empty();

    String vendorCode = "";
    String vendorName = "";

    customerTargetList = payablesList.where((target) {
      return target.postingDateParsed.isAtMost(currentMonthToDate!) &&
          target.bpSubGroup == "Capital Vendors";
    });

    currentMonthActualPayable = modeOfPayment.where((target) {
      return target.postingDateParsed.isAtMost(currentMonthToDate!);
    });

    currentMonthPaid = modeOfPayment.where((target) {
      return target.postingDateParsed.isAtLeast(currentMonthFromDate!) &&
          target.postingDateParsed.isAtMost(currentMonthToDate!);
    });

    Set<String> processedVendorCodes = {};

    for (var customer in customerTargetList.toList()) {
      if (processedVendorCodes.contains(customer.vendorCode)) {
        continue;
      }

      vendorCode = customer.vendorCode;
      vendorName = customer.vendorName;

      double balance = 0.0;
      double overdue = 0.0;

      double a0to30 = 0.0;
      double a31to60 = 0.0;
      double a61to90 = 0.0;
      double a90to180 = 0.0;
      double a180above = 0.0;

      double commitment = 0.0;

      final vendorRows = customerTargetList.where(
        (e) => e.vendorCode == vendorCode,
      );

      for (final sales in vendorRows) {
        final balanceValue = (double.tryParse(sales.balance) ?? 0.0).abs();

        /// Total Payable
        balance += balanceValue;

        /// Commitment
        commitment += double.tryParse(sales.commitment) ?? 0.0;

        switch (sales.ageingBrackets) {
          case "0-30 Days":
            a0to30 += balanceValue;
            overdue += balanceValue;
            break;

          case "31-60 Days":
            a31to60 += balanceValue;
            overdue += balanceValue;
            break;

          case "61-90 Days":
            a61to90 += balanceValue;
            overdue += balanceValue;
            break;

          case "91-180 Days":
            a90to180 += balanceValue;
            overdue += balanceValue;
            break;

          case "Future":
            break;

          default:
            a180above += balanceValue;
            overdue += balanceValue;
            break;
        }
      }

      double actualPayable = currentMonthActualPayable
          .where((entry) => entry.vendorCode == vendorCode)
          .fold(
            0.0,
            (sum, entry) => sum + (double.tryParse(entry.total) ?? 0.0),
          );

      double currentMthPaid = currentMonthPaid
          .where((entry) => entry.vendorCode == vendorCode)
          .fold(
            0.0,
            (sum, entry) => sum + (double.tryParse(entry.total) ?? 0.0),
          );

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
          currentMonthPayable: currentMthPaid,
          actualPayable: actualPayable,
          overDue: overdue,
        ),
      );

      processedVendorCodes.add(vendorCode);
    }

    vendorWiseData.sort((a, b) => a.vendorCode.compareTo(b.vendorCode));

    capitalVendorsList = VendorsPaymentProjectionList(
      vendorData: vendorWiseData,
    );
  }

  Future<void> _loadFixedExpenses() async {
    List<SupplierCategoryWiseAnalysisPayablesData> customerWiseDataList = [];
    DateFormat formatter = DateFormat('dd/MM/yyyy');
    var currentMonthActualPayable = const Iterable.empty();
    var currentMonthPaid = const Iterable.empty();

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

    currentMonthActualPayable = modeOfPayment.where((target) {
      DateTime dueon = target.postingDateParsed;
      return dueon.isAtMost(currentMonthToDate!);
    });

    currentMonthPaid = modeOfPayment.where((target) {
      DateTime dueon = target.postingDateParsed;
      return dueon.isAtLeast(currentMonthFromDate!) &&
          dueon.isAtMost(currentMonthToDate!);
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

      double actualPayable = currentMonthActualPayable
          .where((e) => e.bpSubGroup.trim().toUpperCase() == vendorGroup)
          .fold(0.0, (sum, e) => sum + (double.tryParse(e.total) ?? 0.0));

      double currentMthPaid = currentMonthPaid
          .where((e) => e.bpSubGroup.trim().toUpperCase() == vendorGroup)
          .fold(0.0, (sum, entry) => sum + double.parse(entry.total));

      totalFixedExpensesCommitment += commitment;
      totalFixedExpensesActualPaid += actualPayable;

      customerWiseDataList.add(
        SupplierCategoryWiseAnalysisPayablesData(
          supplierCategoryName: vendorGroup,
          balance: balance.abs(),
          commitment: commitment,
          actualPaid: actualPayable,
          currentMonthPaid: currentMthPaid,
        ),
      );
    }

    customerWiseDataList.sort((a, b) => b.balance.compareTo(a.balance));

    fixedExpensesList = SupplierCategoryWiseAnalysisPayablesList(
      supplierCategoryData: customerWiseDataList,
    );
  }

  Future<void> loadData(String selectedUser) async {
    if (!mounted) return;
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
    await Future.wait([
      _loadPayablesData("", "", "", "", "", ""),
      _loadAdvancePaidData("", "", "", "", "", ""),
      _loadSupplierAnalysis("", "", "", "", "", ""),
      _loadVendorPaymentProjection(),
      _loadSupplierCategoryAnalysis("", "", "", "", "", ""),
      _loadDocumentTypeAnalysis("", "", "", "", "", ""),
      _loadFixedExpenses(),
      _loadBpGroup("", "", "", "", "", ""),
      _loadAdvanceVendors(),
      _loadCapitalVendors(),
    ]);
    refreshPayablesFilterOptions();

    if (savedFinanceReceivablesOptionsTemp.isEmpty) {
      savedFinanceReceivablesOptions = emptyPayablesFilterSelection();
    } else {
      savedFinanceReceivablesOptions = normalizePayablesFilterSelection(
        savedFinanceReceivablesOptionsTemp,
      );
    }
    selectedFinanceReceivablesOptions = normalizePayablesFilterSelection(
      savedFinanceReceivablesOptions,
    );
    if (mounted) {
      await applyPayablesVariables();
      chartDataLoadedPayables = true;
    }
  }

  void refreshPayablesFilterOptions() {
    filterOptions = [
      listOfCategory,
      listOfSupplier,
      ['Not Dues', 'Overdue'],
      ['Advance', 'Payables'],
      [],
    ];
  }

  List<List<bool>> emptyPayablesFilterSelection() {
    return filterOptions
        .map((options) => List<bool>.filled(options.length, false))
        .toList();
  }

  List<List<bool>> normalizePayablesFilterSelection(
    List<List<bool>> selection,
  ) {
    final normalized = emptyPayablesFilterSelection();
    for (
      var catIndex = 0;
      catIndex < filterOptions.length && catIndex < selection.length;
      catIndex++
    ) {
      for (
        var optionIndex = 0;
        optionIndex < filterOptions[catIndex].length &&
            optionIndex < selection[catIndex].length;
        optionIndex++
      ) {
        normalized[catIndex][optionIndex] = selection[catIndex][optionIndex];
      }
    }
    return normalized;
  }

  Map<String, double> payableVendorBalances(Iterable<PayablesList> rows) {
    final balances = <String, double>{};
    for (final row in rows) {
      balances[row.vendorCode] =
          (balances[row.vendorCode] ?? 0) + row.balanceParsed;
    }
    return balances;
  }

  bool isAdvanceVendor(String vendorCode) {
    final vendorBalances = payableVendorBalances(payablesListMaster);
    return (vendorBalances[vendorCode] ?? 0) > 0;
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
    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
    await loadData("");
    if (mounted) {
      setState(() {
        chartDataLoadedPayables = true;
      });
    }
  }

  List<PayablesList> applyFilters() {
    List<PayablesList> list = List.from(payablesListMaster);

    // ---------- Category & Supplier ----------
    final selectedCategories = (allCategoriesState['Category'] ?? {}).entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final selectedSuppliers = (allCategoriesState['Supplier'] ?? {}).entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final selectedDueOptions = (allCategoriesState['Due/Overdue'] ?? {}).entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final selectedAdvancePayables =
        (allCategoriesState['Advance/Payables'] ?? {}).entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

    final vendorBalances = payableVendorBalances(payablesListMaster);

    list = list.where((p) {
      final matchCategory =
          selectedCategories.isEmpty ||
          selectedCategories.contains(p.vendorGroup);

      final matchSupplier =
          selectedSuppliers.isEmpty || selectedSuppliers.contains(p.vendorName);

      final isNotDue = p.ageingBrackets == 'Future';
      final matchDue =
          selectedDueOptions.isEmpty ||
          (selectedDueOptions.contains('Not Dues') && isNotDue) ||
          (selectedDueOptions.contains('Overdue') && !isNotDue);

      final isAdvance = (vendorBalances[p.vendorCode] ?? 0) > 0;
      final matchAdvancePayables =
          selectedAdvancePayables.isEmpty ||
          (selectedAdvancePayables.contains('Advance') && isAdvance) ||
          (selectedAdvancePayables.contains('Payables') && !isAdvance);

      // ---------- Touch Filters ----------

      final matchPayable =
          touchedPayables.isEmpty || p.ageingBrackets == touchedPayables;

      final matchSupplierTouch =
          touchedSupplier.isEmpty || p.vendorName == touchedSupplier;

      final matchCategoryTouch =
          touchedSupplierType.isEmpty || p.vendorGroup == touchedSupplierType;

      final matchDocType =
          touchedDocumentType.isEmpty || p.documentType == touchedDocumentType;

      return matchCategory &&
          matchSupplier &&
          matchDue &&
          matchAdvancePayables &&
          matchPayable &&
          matchSupplierTouch &&
          matchCategoryTouch &&
          matchDocType;
    }).toList();

    // ---------- Date Filter ----------
    if (dateFilterFlag && fromDateFilter != null && toDateFilter != null) {
      list = list.where((p) {
        return p.postingDateParsed.isAtLeast(fromDateFilter!) &&
            p.postingDateParsed.isAtMost(toDateFilter!);
      }).toList();
    }

    return list;
  }

  void clearVariables() {
    setState(() {
      advance = 0.00;
      payables = 0.00;
      actualAdvance = 0;
      chartDataLoadedPayables = false;
      payableGraphList = PayablesGraphList(agingData: []);
      advancePaidList = AdvancePaidToSupplierPayablesList(agingData: []);
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
      touchedBPgroup = "";
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      advance = 0.00;
      payables = 0.00;
      chartDataLoadedPayables = false;
      payableGraphList = PayablesGraphList(agingData: []);
      advancePaidList = AdvancePaidToSupplierPayablesList(agingData: []);
      supplierList = SupplierAnalysisPayablesList(supplierData: []);
      supplierCategoryList = SupplierCategoryWiseAnalysisPayablesList(
        supplierCategoryData: [],
      );
      documentList = DocumentTypeList(documentData: []);
    });
  }

  Future<void> generatePayablesExcel(PayablesGraphList list) async {
    await reportService.generateExcel(
      sheetName: 'Payables',
      headers: ['Ageing Group', 'Ageing Group Total'],
      rows: list.agingData
          .map((e) => [e.agingGroup, e.agingGroupTotal])
          .toList(),
      fileName: 'payables.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Finance - Payables',
    );
  }

  Future<void> generatePayablesPDF(PayablesGraphList list) async {
    await reportService.generatePDF(
      title: 'Payables',
      headers: ['Ageing Group', 'Ageing Group Total'],
      rows: list.agingData
          .map((e) => [e.agingGroup, e.agingGroupTotal])
          .toList(),
      fileName: 'payables.xlsx',
      amountColumns: [2],
    );
  }

  Future<void> generateAdvanceExcel(
    AdvancePaidToSupplierPayablesList list,
  ) async {
    await reportService.generateExcel(
      sheetName: 'AdvancePaid',
      headers: ['Ageing Group', 'Ageing Group Total'],
      rows: list.agingData
          .map((e) => [e.agingGroup, e.agingGroupTotal])
          .toList(),
      fileName: 'advance_paid.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Finance - Advance Paid',
    );
  }

  Future<void> generateAdvancePDF(
    AdvancePaidToSupplierPayablesList list,
  ) async {
    await reportService.generatePDF(
      title: 'Advance Paid To Supplier',
      headers: ['Ageing Group', 'Ageing Group Total'],
      rows: list.agingData
          .map((e) => [e.agingGroup, e.agingGroupTotal])
          .toList(),
      fileName: 'advance_paid.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateSupplierExcel(SupplierAnalysisPayablesList list) async {
    await reportService.generateExcel(
      sheetName: 'SupplierAnalysis',
      headers: ['Supplier Name', 'Balance Amount'],
      rows: list.supplierData.map((e) => [e.supplierName, e.balance]).toList(),
      fileName: 'supplier_analysis.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Finance - Supplier Analysis',
    );
  }

  Future<void> generateSupplierPDF(SupplierAnalysisPayablesList list) async {
    await reportService.generatePDF(
      title: 'Supplier Analysis',
      headers: ['Supplier Name', 'Balance Amount'],
      rows: list.supplierData.map((e) => [e.supplierName, e.balance]).toList(),
      fileName: 'supplier_analysis.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateSupplierCategoryExcel(
    SupplierCategoryWiseAnalysisPayablesList list,
  ) async {
    await reportService.generateExcel(
      sheetName: 'SupplierCategoryAnalysis',
      headers: ['Supplier Category', 'Balance Amount'],
      rows: list.supplierCategoryData
          .map((e) => [e.supplierCategoryName, e.balance])
          .toList(),
      fileName: 'supplier_category_analysis.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Finance - Supplier Category Analysis',
    );
  }

  Future<void> generateSupplierCategoryPDF(
    SupplierCategoryWiseAnalysisPayablesList list,
  ) async {
    await reportService.generatePDF(
      title: 'Supplier Category Analysis',
      headers: ['Supplier Category', 'Balance Amount'],
      rows: list.supplierCategoryData
          .map((e) => [e.supplierCategoryName, e.balance])
          .toList(),
      fileName: 'supplier_category_analysis.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateDocumentTypeExcel(DocumentTypeList list) async {
    await reportService.generateExcel(
      sheetName: 'DocumentTypeAnalysis',
      headers: ['Document Type', 'Amount'],
      rows: list.documentData.map((e) => [e.documentType, e.balance]).toList(),
      fileName: 'document_type.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Finance - Document Type Analysis',
    );
  }

  Future<void> generateDocumentTypePDF(DocumentTypeList list) async {
    await reportService.generatePDF(
      title: 'DocumentTypeAnalysis',
      headers: ['Document Type', 'Amount'],
      rows: list.documentData.map((e) => [e.documentType, e.balance]).toList(),
      fileName: 'document_type.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateVendorPaymentProjectionReport() async {
    await reportService.generateExcel(
      sheetName: 'VendorPaymentProjection',
      headers: [
        'Vendor Code',
        'Vendor Name',
        'Total Payable',
        'Over Due',
        'Future',
        '0-30',
        '31-60',
        '61-90',
        '91-180',
        '180+',
        'Commitment',
        'Curr. Month Paid',
        'YTD Paid',
      ],
      rows: vendorProjectionList.vendorData
          .map(
            (e) => [
              e.vendorCode,
              e.vendorName,
              e.totalPayable,
              e.balanceDue,
              e.future,
              e.a0to30,
              e.a31to60,
              e.a61to90,
              e.a90to180,
              e.a180above,
              e.commitment,
              e.currentMonthPayable,
              e.actualPayable,
            ],
          )
          .toList(),
      fileName: 'vendor_payment_projection.xlsx',
      amountColumns: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13],
      addTotalRow: true,
      reportTitle: 'Finance - Vendor Payment Projection',
    );
  }

  Future<void> generateBgGroup() async {
    await reportService.generateExcel(
      sheetName: 'BusinessPartnerGroupAnalysis',
      headers: [
        'Supplier Category Name',
        'Commitment',
        'Actual Paid(YTD)',
        'Deficit(-)/Surplus(+)',
      ],
      rows: bpGroupList.supplierCategoryData
          .map(
            (e) => [
              e.supplierCategoryName,
              e.commitment,
              e.actualPaid,
              e.actualPaid! - e.commitment!,
            ],
          )
          .toList(),
      fileName: 'business_partner_group_analysis.xlsx',
      amountColumns: [1, 2, 3],
      addTotalRow: true,
      reportTitle: 'Finance - Business Partner Group Analysis',
    );
  }

  Future<void> generateFixedExpenses() async {
    await reportService.generateExcel(
      sheetName: 'FixedExpenses',
      headers: [
        'Supplier Category Name',
        'Target',
        'Current Month Paid',
        'Actual Paid(YTD)',
      ],
      rows: fixedExpensesList.supplierCategoryData
          .map(
            (e) => [
              e.supplierCategoryName,
              e.commitment!.toStringAsFixed(0),
              e.currentMonthPaid!.toStringAsFixed(0),
              e.actualPaid!.toStringAsFixed(0),
            ],
          )
          .toList(),
      fileName: 'fixed_expenses.xlsx',
      amountColumns: [2, 3, 4],
      addTotalRow: true,
      reportTitle: 'Finance - Fixed Expenses Analysis',
    );
  }

  Future<void> generateAdvanceVendors() async {
    await reportService.generateExcel(
      sheetName: 'AdvanceVendors',
      headers: [
        'Supplier Name',
        'Outstanding',
        'Over Due',
        'Current Month Paid',
        'Actual Paid(YTD)',
      ],
      rows: advanceVendorList.supplierData
          .map(
            (e) => [
              e.supplierName,
              e.balance,
              e.overDue,
              e.currentMonthPaid,
              e.actualPaid,
            ],
          )
          .toList(),
      fileName: 'advance_vendors.xlsx',
      amountColumns: [2, 3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Finance - Advance Vendors Analysis',
    );
  }

  Future<void> generateCapitalVendors() async {
    await reportService.generateExcel(
      sheetName: 'CapitalVendors',
      headers: [
        'Vendor Code',
        'Vendor Name',
        'Outstanding',
        'Over Due',
        '0-30',
        '31-60',
        '61-90',
        '91-180',
        '180+',
        'Commitment',
        'Curr. Month Paid',
        'Actual Paid(YTD)',
      ],
      rows: capitalVendorsList.vendorData
          .map(
            (e) => [
              e.vendorCode,
              e.vendorName,
              e.balanceDue,
              e.overDue,
              e.a0to30,
              e.a31to60,
              e.a61to90,
              e.a90to180,
              e.a180above,
              e.commitment,
              e.currentMonthPayable,
              e.actualPayable,
            ],
          )
          .toList(),
      fileName: 'capital_vendors.xlsx',
      amountColumns: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      addTotalRow: true,
      reportTitle: 'Finance - Capital Vendors Analysis',
    );
  }

  Future<void> filterChartFunction() async {
    // Step 1: reset base list
    payablesList = applyFilters();

    // Step 2: run the async loaders
    await Future.wait([
      _loadPayablesData("", "", "", "", "", ""),
      _loadAdvancePaidData("", "", "", "", "", ""),
      _loadSupplierAnalysis("", "", "", "", "", ""),
      _loadVendorPaymentProjection(),
      _loadSupplierCategoryAnalysis("", "", "", "", "", ""),
      _loadDocumentTypeAnalysis("", "", "", "", "", ""),
      _loadBpGroup("", "", "", "", "", ""),
      _loadAdvanceVendors(),
      _loadCapitalVendors(),
      _loadFixedExpenses(),
    ]);

    await applyPayablesVariables();

    setState(() {
      chartDataLoadedPayables = true;
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
    clearVariables();
    refreshPayablesFilterOptions();

    selectedFinanceReceivablesOptions = emptyPayablesFilterSelection();

    savedFinanceReceivablesOptions = normalizePayablesFilterSelection(
      savedFinanceReceivablesOptions,
    );
    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
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
    _payablesHorizontalController.dispose();
    _advancePaidHorizontalController.dispose();
    _supplierHorizontalController.dispose();
    _supplierCategoryHorizontalController.dispose();
    _documentTypeHorizontalController.dispose();
    _bpGroupHorizontalController.dispose();
    _advanceVendorsHorizontalController.dispose();
    _capitalVendorsHorizontalController.dispose();
    _fixedExpensesHorizontalController.dispose();
    super.dispose();
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _payablesHorizontalController = ScrollController();
  final ScrollController _advancePaidHorizontalController = ScrollController();
  final ScrollController _supplierHorizontalController = ScrollController();
  final ScrollController _supplierCategoryHorizontalController =
      ScrollController();
  final ScrollController _documentTypeHorizontalController = ScrollController();
  final ScrollController _bpGroupHorizontalController = ScrollController();
  final ScrollController _advanceVendorsHorizontalController =
      ScrollController();
  final ScrollController _capitalVendorsHorizontalController =
      ScrollController();
  final ScrollController _fixedExpensesHorizontalController =
      ScrollController();

  @override
  Widget build(BuildContext context) {
    DateTime currentDate = DateTime.now();
    return chartDataLoadedPayables == true
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
                                  generateBgGroup();
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
                        // percent: netPayablePercentage / 100,
                        percent: ((netPayablePercentage / 100).clamp(
                          0.0,
                          1.0,
                        )).toDouble(),
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
                                  "Over Due $overDueStr",
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
                        // percent: payableAdvancePercentage / 100,
                        percent: ((payableAdvancePercentage / 100).clamp(
                          0.0,
                          1.0,
                        )).toDouble(),
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

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'Vendor Payment Projection',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateVendorPaymentProjectionReport();
                        },
                        child: const Text('Download Vendor Payment Projection'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generatePayablesExcel(payableGraphList);
                        },
                        child: const Text('Download Excel'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generatePayablesPDF(payableGraphList);
                        },
                        child: const Text('Download PDF'),
                      ),
                    ],
                    child: _payables(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'Advance Paid to Supplier',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateAdvanceExcel(advancePaidList);
                        },
                        child: const Text('Download Excel'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateAdvancePDF(advancePaidList);
                        },
                        child: const Text('Download PDF'),
                      ),
                    ],
                    child: _advancePaidToSupplier(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'Supplier Analysis',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateSupplierExcel(supplierList);
                        },
                        child: const Text('Download Excel'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateSupplierPDF(supplierList);
                        },
                        child: const Text('Download PDF'),
                      ),
                    ],
                    child: _supplierAnalysis(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'Supplier Category Wise Analysis',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateSupplierCategoryExcel(supplierCategoryList);
                        },
                        child: const Text('Download Excel'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateSupplierCategoryPDF(supplierCategoryList);
                        },
                        child: const Text('Download PDF'),
                      ),
                    ],
                    child: _supplierCategoryWiseAnalysis(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'Document Type Analysis',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateDocumentTypeExcel(documentList);
                        },
                        child: const Text('Download Excel'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateDocumentTypePDF(documentList);
                        },
                        child: const Text('Download PDF'),
                      ),
                    ],
                    child: _documentTypeAnalysis(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'BP Group Summary',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateBgGroup();
                        },
                        child: const Text('Download Excel'),
                      ),
                    ],
                    child: _bpGroup(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'Advance Vendors',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateAdvanceVendors();
                        },
                        child: const Text('Download Excel'),
                      ),
                    ],
                    child: _advanceVendors(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'Capital Vendors',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateCapitalVendors();
                        },
                        child: const Text('Download Excel'),
                      ),
                    ],
                    child: _capitalVendors(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'Fixed Expenses',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateFixedExpenses();
                        },
                        child: const Text('Download Excel'),
                      ),
                    ],
                    child: _fixedExpenses(),
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
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
    return FinanceHorizontalChartScroll(
      controller: _payablesHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: screenWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              minY: chartMinY,
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
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
                        loadDataFuture = filterChartFunction();
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
                              ' ${formatAmount(payableGraphList.agingData[0].agingGroupTotal)} \n',
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${payableGraphList.agingData[1].agingGroup} '
                              ': ${formatAmount(payableGraphList.agingData[1].agingGroupTotal)} \n',
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${payableGraphList.agingData[2].agingGroup} '
                              ': ${formatAmount(payableGraphList.agingData[2].agingGroupTotal)} \n',
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${payableGraphList.agingData[3].agingGroup} '
                              ': ${formatAmount(payableGraphList.agingData[3].agingGroupTotal)} \n',
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${payableGraphList.agingData[4].agingGroup} '
                              ': ${formatAmount(payableGraphList.agingData[4].agingGroupTotal)} \n',
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${payableGraphList.agingData[5].agingGroup} '
                              ': ${formatAmount(payableGraphList.agingData[5].agingGroupTotal)} \n',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              'Total'
                              ': ${formatAmount(payableGraphList.agingData[5].agingGroupTotal + payableGraphList.agingData[4].agingGroupTotal + payableGraphList.agingData[3].agingGroupTotal + payableGraphList.agingData[2].agingGroupTotal + payableGraphList.agingData[1].agingGroupTotal + payableGraphList.agingData[0].agingGroupTotal)}',
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

  Widget _advancePaidToSupplier() {
    final screenWidth = MediaQuery.of(context).size.width;

    final amounts = advancePaidList.agingData
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

    return FinanceHorizontalChartScroll(
      controller: _advancePaidHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: screenWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              minY: chartMinY,
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
              barGroups: _advancePaidChartData(advancePaidList.agingData),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        touchedAdvancePaid = touchedAdvancePaid == ""
                            ? advancePaidList
                                  .agingData[barTouchResponse.spot!.spot.x
                                      .toInt()]
                                  .agingGroup
                            : "";
                        selectedChart = barTouchResponse.spot!.spot.x;
                        showDrillDownChart = true;
                        loadDataFuture = filterChartFunction();
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
                              '${advancePaidList.agingData[0].agingGroup} :'
                              ' ${(advancePaidList.agingData[0].agingGroupTotal / 1000000).toStringAsFixed(2)} L\n',
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${advancePaidList.agingData[1].agingGroup} '
                              ': ${formatAmount(advancePaidList.agingData[1].agingGroupTotal)} \n',
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${advancePaidList.agingData[2].agingGroup} '
                              ': ${formatAmount(advancePaidList.agingData[2].agingGroupTotal)} \n',
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${advancePaidList.agingData[3].agingGroup} '
                              ': ${formatAmount(advancePaidList.agingData[3].agingGroupTotal)} \n',
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${advancePaidList.agingData[4].agingGroup} '
                              ': ${formatAmount(advancePaidList.agingData[4].agingGroupTotal)} \n',
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${advancePaidList.agingData[5].agingGroup} '
                              ': ${formatAmount(advancePaidList.agingData[5].agingGroupTotal)} \n',
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              'Total'
                              ': ${formatAmount(advancePaidList.agingData[5].agingGroupTotal + advancePaidList.agingData[4].agingGroupTotal + advancePaidList.agingData[3].agingGroupTotal + advancePaidList.agingData[2].agingGroupTotal + advancePaidList.agingData[1].agingGroupTotal + advancePaidList.agingData[0].agingGroupTotal)}',
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
    return FinanceHorizontalChartScroll(
      controller: _supplierHorizontalController,
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
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
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
                        loadDataFuture = filterChartFunction();
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
    return FinanceHorizontalChartScroll(
      controller: _supplierCategoryHorizontalController,
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
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
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
                        loadDataFuture = filterChartFunction();
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
    return FinanceHorizontalChartScroll(
      controller: _documentTypeHorizontalController,
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
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
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
                        loadDataFuture = filterChartFunction();
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
    return FinanceHorizontalChartScroll(
      controller: _bpGroupHorizontalController,
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
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
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
                        loadDataFuture = filterChartFunction();
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
    return FinanceHorizontalChartScroll(
      controller: _advanceVendorsHorizontalController,
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
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
              barGroups: _advanceVendorChartData(
                advanceVendorList.supplierData,
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
    return FinanceHorizontalChartScroll(
      controller: _capitalVendorsHorizontalController,
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
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
              barGroups: _capitalVendorsChartData(
                capitalVendorsList.vendorData,
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
    return FinanceHorizontalChartScroll(
      controller: _fixedExpensesHorizontalController,
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
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
      ),
    );
  }

  void showFilterBottomSheet(BuildContext context) {
    int selectedCategoryIndex = 0;
    String filterSearchText = "";
    // restore previous selections ONLY when opening sheet
    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions
        .map((e) => List<bool>.from(e))
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final isSearchableFilter =
                categories[selectedCategoryIndex] == 'Supplier';
            final visibleFilterIndexes =
                List<int>.generate(
                  filterOptions[selectedCategoryIndex].length,
                  (index) => index,
                ).where((index) {
                  if (!isSearchableFilter || filterSearchText.trim().isEmpty) {
                    return true;
                  }
                  return filterOptions[selectedCategoryIndex][index]
                      .toLowerCase()
                      .contains(filterSearchText.trim().toLowerCase());
                }).toList();

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
                                  modalSetState(() {
                                    selectedCategoryIndex = index;
                                    filterSearchText = "";
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
                                        categories.indexOf('Date')
                                    ?
                                      // Column(
                                      //     children: [
                                      //       ListTile(
                                      //         title: const Text("To Date"),
                                      //         subtitle: Text(
                                      //           toDateFilter != null
                                      //               ? "${toDateFilter!.day}/${toDateFilter!.month}/${toDateFilter!.year}"
                                      //               : formatDateString(
                                      //                   currentDate!,
                                      //                 ),
                                      //         ),
                                      //         trailing: const Icon(
                                      //           Icons.calendar_today,
                                      //         ),
                                      //         onTap: () async {
                                      //           final picked =
                                      //               await showDatePicker(
                                      //                 context: context,
                                      //                 initialDate:
                                      //                     toDateFilter ??
                                      //                     DateTime.now(),
                                      //                 firstDate:
                                      //                     fiscalYearStartDate!,
                                      //                 lastDate: currentDate!,
                                      //               );
                                      //           if (picked != null) {
                                      //             modalSetState(() {
                                      //               toDateFilter = picked;
                                      //               dateFilterFlag = true;
                                      //             });
                                      //           }
                                      //         },
                                      //       ),
                                      //     ],
                                      //   )
                                      Column(
                                        children: [
                                          // FROM DATE
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
                                                        fiscalYearStartDate!,
                                                    firstDate:
                                                        fiscalYearStartDate!,
                                                    lastDate:
                                                        toDateFilter ??
                                                        currentDate!,
                                                  );

                                              if (picked != null) {
                                                modalSetState(() {
                                                  fromDateFilter = picked;
                                                  dateFilterFlag = true;
                                                });
                                              }
                                            },
                                          ),

                                          // TO DATE
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
                                                        currentDate!,
                                                    firstDate:
                                                        fromDateFilter ??
                                                        fiscalYearStartDate!,
                                                    lastDate: currentDate!,
                                                  );

                                              if (picked != null) {
                                                modalSetState(() {
                                                  toDateFilter = picked;
                                                  dateFilterFlag = true;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          if (isSearchableFilter)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      prefixIcon: Icon(
                                                        Icons.search,
                                                      ),
                                                      hintText:
                                                          'Search supplier',
                                                      border:
                                                          OutlineInputBorder(),
                                                      isDense: true,
                                                    ),
                                                onChanged: (value) {
                                                  modalSetState(() {
                                                    filterSearchText = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount:
                                                  visibleFilterIndexes.length,
                                              itemBuilder: (context, index) {
                                                final optionIndex =
                                                    visibleFilterIndexes[index];
                                                return CheckboxListTile(
                                                  title: Text(
                                                    filterOptions[selectedCategoryIndex][optionIndex],
                                                  ),
                                                  value:
                                                      savedFinanceReceivablesOptions[selectedCategoryIndex][optionIndex],
                                                  onChanged: (bool? value) {
                                                    modalSetState(() {
                                                      final currentCategory =
                                                          categories[selectedCategoryIndex];

                                                      final isSingleSelect =
                                                          currentCategory ==
                                                              'Advance/Payables' ||
                                                          currentCategory ==
                                                              'Due/Overdue';

                                                      if (isSingleSelect &&
                                                          value == true) {
                                                        for (
                                                          int i = 0;
                                                          i <
                                                              selectedFinanceReceivablesOptions[selectedCategoryIndex]
                                                                  .length;
                                                          i++
                                                        ) {
                                                          selectedFinanceReceivablesOptions[selectedCategoryIndex][i] =
                                                              false;
                                                        }
                                                      }

                                                      selectedFinanceReceivablesOptions[selectedCategoryIndex][optionIndex] =
                                                          value == true;

                                                      savedFinanceReceivablesOptionsTemp =
                                                          savedFinanceReceivablesOptions
                                                              .map(
                                                                (e) =>
                                                                    List<
                                                                      bool
                                                                    >.from(e),
                                                              )
                                                              .toList();

                                                      if (savedFinanceReceivablesOptions
                                                          .isEmpty) {
                                                        savedFinanceReceivablesOptionsTemp =
                                                            savedFinanceReceivablesOptions
                                                                .map(
                                                                  (e) =>
                                                                      List<
                                                                        bool
                                                                      >.from(e),
                                                                )
                                                                .toList();
                                                      }

                                                      savedFinanceReceivablesOptions =
                                                          selectedFinanceReceivablesOptions;
                                                    });
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
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
                                    onPressed: () async {
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

                                      selectedSalesData = selectedFilterOptions;

                                      savedFinanceReceivablesOptionsTemp =
                                          savedFinanceReceivablesOptions
                                              .map((e) => List<bool>.from(e))
                                              .toList();

                                      fromFilter = true;
                                      setState(() {
                                        chartDataLoadedPayables = false;
                                      });

                                      Navigator.pop(context);

                                      Future.delayed(
                                        const Duration(milliseconds: 300),
                                        () async {
                                          if (!mounted) return;

                                          setState(() {
                                            chartDataLoadedPayables = false;
                                          });

                                          await filterChartFunction();
                                        },
                                      );
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
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        loadDataFuture = removeFilter();
                                        Navigator.pop(context);
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Remove Filter',
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
