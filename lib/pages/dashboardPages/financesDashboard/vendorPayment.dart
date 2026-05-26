// ignore_for_file: file_names, use_build_context_synchronously, non_constant_identifier_names, strict_top_level_inference
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/leads.dart';
import '../../../api_helper.dart';
import '../../../classes/dashBoard.dart';
import '../../../login_screen.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../ReportService.dart';

final reportService = ReportService();

class ReceivablesData {
  final double receivableAmount;
  ReceivablesData({required this.receivableAmount});
}

class CollectionAnalysisTableData {
  final String invoiceDate;
  final double deliveryValue;
  final String deliveryStatus;
  final String deliveryRemarks;
  CollectionAnalysisTableData({
    required this.invoiceDate,
    required this.deliveryValue,
    required this.deliveryStatus,
    required this.deliveryRemarks,
  });
}

class Distributor {
  String customerName;
  String customerCode;
  Distributor({required this.customerCode, required this.customerName});
}

class InvoiceWrapper {
  PayablesList invoice;
  bool isChecked;

  InvoiceWrapper({required this.invoice, required this.isChecked});
}

ReceivablesAgingList receivablesAgingList = ReceivablesAgingList(agingData: []);

String deviceOrientation = "";
final TextEditingController customerController = TextEditingController();
final TextEditingController asmController = TextEditingController();
final TextEditingController valueController = TextEditingController();
late Future<void> loadDataFuture;

double totalValue = 0.0;
List<Distributor> dList = [];
List<Users> usersList = [];
List<Users> childUsers = [];
bool noUserList = false;
List<CollectionList> collection = [];
List<PayablesList> target = [];
List<PayablesList> invoiceList = [];
List<PayablesList> invoiceListTemp = [];
List<PayablesList> selectedInvoiceList = [];
List<Users> usersListForFilter = [];
List<InvoiceCustomers> customers = [];
// List<InvoiceCustomers> asmList = [];
List<UsersForSearch> asmList = [];
List<Map<String, dynamic>> userList = [];
List<MyNode> nodes = [];
double remainingCommitment = 0;

enum VendorPaymentViewType { vendorWise, billWise }

class VendorPayment extends StatefulWidget {
  const VendorPayment({super.key});

  @override
  State<VendorPayment> createState() => _VendorPaymentState();
}

Color getCategoryColor(String category) {
  switch (category) {
    case const ("0-30"):
      return Colors.green;
    case const ("31-60"):
      return Colors.blue;
    case const ("61-90"):
      return Colors.orange;
    case const ("90+"):
      return Colors.grey;
    default:
      return const Color(0xFF6CCC3F);
  }
}

List<PieChartSectionData> showingSections() {
  final List<PieChartSectionData> sections = [];
  for (final categoryData in receivablesAgingList.agingData) {
    final fontSize = touchedIndex >= 1 ? 12.0 : 11.0;
    final radius = touchedIndex >= 1 ? 80.0 : 75.0;
    const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

    // Create PieChartSectionData based on categoryData
    final sectionData = PieChartSectionData(
      color: getCategoryColor(
        categoryData.agingGroup,
      ), // Define a method to get color based on categoryId
      value: categoryData.agingPercentage.abs(),
      title: '${categoryData.agingPercentage.abs().toStringAsFixed(2)} %',
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

int touchedIndex = -1;
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

List<Map<String, dynamic>> selectedInvoices = [];

String collectionAchievedStr = "";
double collectionAchieved = 0;
double collectionAgingGoal = 0;
String collectionAgingGoalStr = "";
int collectionPercentage = 0;
String collectionPercentageStr = "";

List<bool> collectionCheckList = List.generate(
  invoiceList.length,
  (index) => false,
);

bool chartDataLoaded = false;
String? selectedModeOfPayment;
List<ModeOfPaymentList> modeOfPayment = [];

VendorsPaymentProjectionList vendorProjectionList =
    VendorsPaymentProjectionList(vendorData: []);

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

bool fromFilter = false;

Map<String, Map<String, bool>> allCategoriesState = {};

final List<String> categories = ['Date'];

List<List<String>> filterOptions = [[]];

List<String> selectedSalesData = [];

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

class CollectionAnalysisCustomerDashboardProvider with ChangeNotifier {
  List<CollectionList> _collectionList = [];
  List<CollectionList> get collectionList => _collectionList;
  void updateCollectionList(List<CollectionList> newCollectionList) {
    _collectionList = newCollectionList;
    notifyListeners();
  }
}

class VendorPaymentProvider with ChangeNotifier {
  List<PayablesList> _targetList = [];
  List<PayablesList> get targetList => _targetList;
  void updateTargetList(List<PayablesList> newTargetList) {
    _targetList = newTargetList;
    notifyListeners();
  }
}

class VendorPayableProvider with ChangeNotifier {
  List<ModeOfPaymentList> _targetList = [];
  List<ModeOfPaymentList> get targetList => _targetList;
  void updateTargetList(List<ModeOfPaymentList> newTargetList) {
    _targetList = newTargetList;
    notifyListeners();
  }
}

class _VendorPaymentState extends State<VendorPayment> {
  VendorPaymentViewType selectedViewType = VendorPaymentViewType.vendorWise;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController paymentRemarksController =
      TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController commitmentController = TextEditingController();
  final TextEditingController vendorSearchController = TextEditingController();
  String? selectedModeOfPayment = "Payment Outstanding Invoice";
  DateTime selectedCommitmentMonth = DateTime.now();
  late FocusNode _focusInvoice;
  List<VendorCommitmentSummary> vendorSummaryList = [];
  List<VendorCommitmentSummary> filteredVendorSummaryList = [];
  final Map<String, TextEditingController> vendorCommitmentControllers = {};
  Map<String, VendorMonthCommitment> vendorCommitments = {};

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.black, fontSize: 10);
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Credit \nPeriod', style: style);
        break;
      case 1:
        text = const Text('0-30 \nDays', style: style);
        break;
      case 2:
        text = const Text('31-60 \nDays', style: style);
        break;
      case 3:
        text = const Text('61-90 \nDays', style: style);
        break;
      case 4:
        text = const Text('91+ \nDays', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(meta: meta, space: 16, child: text);
  }

  var distributorKey = GlobalKey();
  var asmKey = GlobalKey();
  List<Map<String, dynamic>> distributorList = [];
  String selectedDistributorName = "";
  String selectedASMName = "";
  String selectedDistributorId = "";

  List<Distributor> convertDist(List<Map<String, dynamic>> distributorList) {
    return distributorList
        .map(
          (map) => Distributor(
            customerCode: map['CustomerCode']?.toString() ?? '',
            customerName: map['CustomerName']?.toString() ?? '',
          ),
        )
        .toList();
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

  Future<List<InvoiceCustomers>> getDistributor(String search) async {
    final seen = <String>{};
    List<InvoiceCustomers> filteredList = invoiceListTemp
        .where(
          (element) =>
              element.vendorName.toLowerCase().startsWith(search.toLowerCase()),
        )
        .map(
          (e) => InvoiceCustomers(
            customerName: e.vendorName,
            customerCode: e.vendorCode.toString(),
            salesManager: "",
            regionalManager: "",
          ),
        )
        .where(
          (e) => seen.add(e.customerCode),
        ) // Keeps only unique customerCodes
        .toList();
    return filteredList;
  }

  Future<List<UsersForSearch>> getASM(String search) async {
    List<UsersForSearch> filteredList = asmList
        .where(
          (element) =>
              element.menuName.toLowerCase().startsWith(search.toLowerCase()),
        )
        .toList();

    return filteredList;
  }

  Future<List<UsersForSearch>> getUsers(String search) async {
    List<UsersForSearch> filteredList = usersList
        .where(
          (element) =>
              element.userLevel == 2 &&
              element.menuName.toLowerCase().startsWith(search.toLowerCase()),
        )
        .map(
          (e) =>
              UsersForSearch(menuName: e.menuName, menuId: e.menuId.toString()),
        )
        .toList();

    return filteredList;
  }

  double _invoiceBalance(PayablesList invoice) {
    return double.tryParse(invoice.balance)?.abs() ?? 0;
  }

  void sortInvoicesByDate({bool checkAllOnLengthMismatch = false}) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final hasMatchingCheckState =
        collectionCheckList.length == invoiceList.length;

    final combinedList = List.generate(
      invoiceList.length,
      (i) => InvoiceWrapper(
        invoice: invoiceList[i],
        isChecked: hasMatchingCheckState
            ? collectionCheckList[i]
            : checkAllOnLengthMismatch,
      ),
    );

    combinedList.sort((a, b) {
      final dateA = formatter.parse(a.invoice.dueon);
      final dateB = formatter.parse(b.invoice.dueon);
      return dateA.compareTo(dateB);
    });

    invoiceList = combinedList.map((e) => e.invoice).toList();
    collectionCheckList = combinedList.map((e) => e.isChecked).toList();
    _refreshSelectedInvoiceTotal();
  }

  void _selectAllVisibleInvoices() {
    double total = 0;

    collectionCheckList = List<bool>.filled(invoiceList.length, true);
    selectedInvoiceList = List.from(invoiceList);

    for (final invoice in invoiceList) {
      total += _invoiceBalance(invoice);
    }

    totalValue = total;
    valueController.text = total.toStringAsFixed(0);
    remainingCommitment = 0;
  }

  void _refreshSelectedInvoiceTotal() {
    double total = 0;
    selectedInvoiceList.clear();

    for (var i = 0; i < invoiceList.length; i++) {
      if (!collectionCheckList[i]) continue;

      total += _invoiceBalance(invoiceList[i]);
      selectedInvoiceList.add(invoiceList[i]);
    }

    totalValue = total;
    valueController.text = total.toStringAsFixed(0);
  }

  void _clearVendorFilter() {
    selectedDistributorId = "";
    selectedDistributorName = "";
    customerController.clear();
    customerController.value = TextEditingValue.empty;
    _applyInvoiceFilters();
  }

  Future<void> _runFilterWithLoader(VoidCallback updateFilter) async {
    if (!mounted) return;
    setState(() {
      chartDataLoaded = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    setState(() {
      updateFilter();
      chartDataLoaded = true;
    });
  }

  void _applyInvoiceFilters() {
    final selectedVendor = customerController.text.toLowerCase().trim();

    invoiceList = invoiceListTemp.where((invoice) {
      return selectedVendor.isEmpty
          ? true
          : invoice.vendorName.toLowerCase() == selectedVendor;
    }).toList();

    sortInvoicesByDate(checkAllOnLengthMismatch: true);
    _selectAllVisibleInvoices();
  }

  void _applyCommitmentDistribution() {
    double remaining = double.tryParse(commitmentController.text) ?? 0;

    sortInvoicesByDate(checkAllOnLengthMismatch: true);

    for (final item in invoiceList) {
      item.commitment = "0";
    }

    if (remaining <= 0) {
      remainingCommitment = 0;
      return;
    }

    for (var i = 0; i < invoiceList.length; i++) {
      if (!collectionCheckList[i]) continue;

      final balance = _invoiceBalance(invoiceList[i]);
      if (remaining <= 0) break;

      if (remaining >= balance) {
        invoiceList[i].commitment = balance.toStringAsFixed(2);
        remaining -= balance;
      } else {
        invoiceList[i].commitment = remaining.toStringAsFixed(2);
        remaining = 0;
      }
    }

    remainingCommitment = remaining;
  }

  void applyCommitmentDistribution() {
    setState(() {
      _applyCommitmentDistribution();
    });
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
    switch (getCurrentQuarter()) {
      case 1:
        lastQuarterFromDate = DateTime(currentDate!.year, 1, 1);
        lastQuarterToDate = DateTime(currentDate!.year, 4, 0);
      case 2:
        lastQuarterFromDate = DateTime(currentDate!.year, 4, 1);
        lastQuarterToDate = DateTime(currentDate!.year, 8, 0);
      case 3:
        lastQuarterFromDate = DateTime(currentDate!.year, 7, 1);
        lastQuarterToDate = DateTime(currentDate!.year, 10, 0);
      case 4:
        lastQuarterFromDate = DateTime(currentDate!.year, 10, 1);
        lastQuarterToDate = DateTime(currentDate!.year, 13, 0);
      default:
        throw Error();
    }
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
    currentMonthToDate = addMonth(
      currentMonthFromDate!,
      1,
    ).add(const Duration(days: -1));
    lastMonthFromDate = DateTime(currentDate!.year, currentDate!.month - 1, 1);
    lastMonthToDate = DateTime(currentDate!.year, currentDate!.month, 0);
    int fiscalYearStartMonth = 4;
    currentQuarter = getCurrentQuarter();
    getLastQuarterDates();
    switch (currentQuarter) {
      case 1:
        currentQuarterFromDate = DateTime(currentDate!.year, 4, 1);
        currentQuarterToDate = DateTime(currentDate!.year, 7, 0);
      case 2:
        currentQuarterFromDate = DateTime(currentDate!.year, 7, 1);
        currentQuarterToDate = DateTime(currentDate!.year, 10, 0);
      case 3:
        currentQuarterFromDate = DateTime(currentDate!.year, 10, 1);
        currentQuarterToDate = DateTime(currentDate!.year, 13, 0);
      case 4:
        currentQuarterFromDate = DateTime(
          currentDate!.year + 1,
          currentQuarter - 3,
          1,
        );
        currentQuarterToDate = DateTime(
          currentDate!.year + 1,
          currentQuarter,
          0,
        );
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
    final formatter = DateFormat('ddMMyyyy');
    return formatter.format(date);
  }

  String formatTestDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  String convertToCustomDateFormat(String inputDate) {
    try {
      DateTime parsedDate = DateTime.parse(inputDate.substring(0, 10));
      String formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);
      return formattedDate;
    } catch (e) {
      return 'Invalid date format';
    }
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

  Future<void> prepareVendorSummary() async {
    final Map<String, VendorCommitmentSummary> temp = {};

    for (var invoice in invoiceList) {
      final vendorCode = invoice.vendorCode;
      final vendorName = invoice.vendorName;
      final outstanding = _invoiceBalance(invoice);

      if (temp.containsKey(vendorCode)) {
        temp[vendorCode]!.totalOutstanding += outstanding;
      } else {
        temp[vendorCode] = VendorCommitmentSummary(
          vendorCode: vendorCode,
          vendorName: vendorName,
          totalOutstanding: outstanding,
        );
      }
    }

    vendorSummaryList = temp.values.toList();
    vendorSummaryList.sort(
      (a, b) => b.totalOutstanding.compareTo(a.totalOutstanding),
    );
    filteredVendorSummaryList = List.from(vendorSummaryList);
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
    LoadDates();
    await _loadUserList(
      userId,
      userJwtToken,
      userMailID,
      int.tryParse(userLevel) ?? 0,
    );
    await _loadCollectionTarget(userName, userLevel);
    await _loadModeOfPayment(userName, userLevel);
    await _loadReceivablesAgingData(
      0,
      "",
      "",
      "",
      ""
          "",
      "",
    );
    await _loadVendorPaymentProjection();
    await prepareVendorSummary();
    await loadSavedVendorCommitment();
    collectionAchieved = 0;
    for (var i = 0; i < collectionCheckList.length; i++) {
      collectionAchieved += _invoiceBalance(invoiceList[i]);
    }
    if (!mounted) return;
    setState(() {
      chartDataLoaded = true;
    });
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
              usersList = (data).map((item) => Users.fromJson(item)).toList();
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
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          }
        }
      } else {
        const snackBar = SnackBar(content: Text('User list not found.'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  AgingSummary summarizeCollectionTargets(
    Iterable<PayablesList> collectionTargetList,
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

  Future<void> _loadReceivablesAgingData(
    int monthIndex,
    String touchedRegionalManager,
    String salesManager,
    String salesRep,
    String customerCode,
    String touchedAgingCategory,
  ) async {
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Reset global before reuse (IMPORTANT)
    collectionAgingGoal = 0;

    // Filter
    final collectionTargetList = target.where((t) {
      final date = dateFormat.parse(t.dueon);
      return date.isAtMost(currentMonthToDate!);
    });

    // Summary
    final summary = summarizeCollectionTargets(collectionTargetList);

    final agingGroup1Total = summary.a0to30DaysTotal;
    final agingGroup2Total = summary.a31to60DaysTotal;
    final agingGroup3Total = summary.a61to90DaysTotal;
    final agingGroup4Total = summary.a91to180DaysTotal + summary.a181DaysTotal;

    final totalDueAmount =
        agingGroup1Total +
        agingGroup2Total +
        agingGroup3Total +
        agingGroup4Total;

    final receivablesAgingDataList = [
      ReceivablesAgingData(
        agingGroup: "0-30",
        agingGroupTotal: agingGroup1Total.abs(),
        agingPercentage: 0,
        agingTotal: totalDueAmount.abs(),
      ),
      ReceivablesAgingData(
        agingGroup: "31-60",
        agingGroupTotal: agingGroup2Total.abs(),
        agingPercentage: 0,
        agingTotal: totalDueAmount.abs(),
      ),
      ReceivablesAgingData(
        agingGroup: "61-90",
        agingGroupTotal: agingGroup3Total.abs(),
        agingPercentage: 0,
        agingTotal: totalDueAmount.abs(),
      ),
      ReceivablesAgingData(
        agingGroup: "90+",
        agingGroupTotal: agingGroup4Total.abs(),
        agingPercentage: 0,
        agingTotal: totalDueAmount.abs(),
      ),
    ];

    for (var agingData in receivablesAgingDataList) {
      // Safe percentage
      final percentage = totalDueAmount == 0
          ? 0
          : (agingData.agingGroupTotal / totalDueAmount) * 100;

      agingData.agingPercentage = double.parse(percentage.toStringAsFixed(2));

      agingData.agingGroupTotal = double.parse(
        agingData.agingGroupTotal.toStringAsFixed(2),
      );

      collectionAgingGoal += agingData.agingGroupTotal;
    }

    // Keep your original logic
    collectionAgingGoal += collectionAchieved;
    collectionAgingGoalStr = formatAmount(collectionAgingGoal);

    if (collectionAchieved == 0) {
      collectionPercentage = 0;
    } else {
      collectionPercentage =
          ((collectionAgingGoal.abs() / collectionAchieved.abs()) * 100).ceil();
    }

    receivablesAgingList = ReceivablesAgingList(
      agingData: receivablesAgingDataList,
    );
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

  Future<void> _loadCollectionTarget(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<PayablesList> targetList = [];

    try {
      final fromDate = dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      do {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index,
          "Limit": limit,
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}BicxoCreditorsAgingList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);
          final data = responseJson['responseData'] as List?;

          if (data != null && data.isNotEmpty) {
            final newList = data.map((e) => PayablesList.fromJson(e)).toList();

            targetList.addAll(newList);
            fetchedCount = newList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      if (!mounted) return;

      // Single pass processing (IMPORTANT)
      double sum = 0;
      List<PayablesList> invoiceListLocal = [];
      Set<InvoiceCustomers> customerSet = {};

      final dateFormat = DateFormat('dd/MM/yyyy');

      for (var item in targetList) {
        // Parse date ONCE
        final dueDate = dateFormat.parse(item.dueon);

        // Current month calculation
        if (dueDate.isAtMost(currentMonthToDate!)) {
          sum += double.tryParse(item.balance) ?? 0;
        }

        // Invoice filter
        if (item.documentType == "Invoice") {
          invoiceListLocal.add(item);

          customerSet.add(
            InvoiceCustomers(
              customerName: item.vendorName,
              customerCode: item.vendorCode,
              salesManager: "",
              regionalManager: "",
            ),
          );
        }
      }

      // UI update (lightweight)
      setState(() {
        context.read<VendorPaymentProvider>().updateTargetList(targetList);

        target = targetList;

        collectionAchieved = sum;
        collectionAchievedStr = sum.toString();

        invoiceList = invoiceListLocal;
        invoiceListTemp = List.from(invoiceListLocal);
        sortInvoicesByDate(checkAllOnLengthMismatch: true);
        _selectAllVisibleInvoices();

        customers = customerSet.toList();
        asmList = asmList.toSet().toList();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _loadModeOfPayment(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;

    List<ModeOfPaymentList> salesList = [];

    try {
      final fromDate = dateFilterFlag
          ? formatTestDate(fromDateFilter!)
          : formatTestDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatTestDate(toDateFilter!)
          : formatTestDate(currentDate!);

      do {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index,
          "Limit": limit,
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}BicxoPaymentAnalysisList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);
          final data = responseJson['responseData'] as List?;

          if (data != null && data.isNotEmpty) {
            final newList = data
                .map((e) => ModeOfPaymentList.fromJson(e))
                .toList();

            salesList.addAll(newList);
            fetchedCount = newList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      if (!mounted) return;

      // Minimal UI update only
      setState(() {
        context.read<VendorPayableProvider>().updateTargetList(salesList);

        if (modeOfPayment.isEmpty) {
          modeOfPayment = salesList; // no .toList()
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String leftDouble = "";
      leftDouble = formatAmount(value.abs());
      return Text(leftDouble, style: const TextStyle(fontSize: 12));
    },
  );

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

  Future<bool> submitCommitments() async {
    String date = _dateController.text;

    selectedInvoices = selectedInvoiceList
        .whereType<PayablesList>()
        .where((item) => (double.tryParse(item.commitment.toString()) ?? 0) > 0)
        .map(
          (PayablesList item) => {
            'InvoiceNo': item.documentNumber,
            'InvoiceIssues': selectedModeOfPayment,
            'InvoiceExpPayDate': date,
            'InvoiceExpPayRemarks': paymentRemarksController.text,
            'InvoiceOtherRemarks': remarksController.text,
            'InvoiceCommitments': item.commitment,
          },
        )
        .toList();

    final leadmaster = {
      'SalesCommentUpdate': selectedInvoices,
      "sapToken": DataManager.readSapToken(),
    };
    const apiUrl = '${ApiHelper.baseUrl}CRMPurchaseCommentsUpdate';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(leadmaster),
        headers: headerss,
      );
      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      if (responseJson["statusCode"] == 1) {
        setState(() {
          selectedInvoiceList = [];
        });
        const snackBar = SnackBar(
          duration: Duration(seconds: 1),
          content: Text(
            'Saved Successfully...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return true;
      } else {
        const snackBar = SnackBar(
          content: Text('Payment comments updation failed'),
        );
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return false;
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return false;
    }
  }

  List<Map<String, dynamic>> generateVendorSAPCommitments() {
    final List<Map<String, dynamic>> selectedInvoices = [];
    final expectedPaymentDate = DateFormat('yyyy-MM-dd').format(
      DateTime(
        selectedCommitmentMonth.year,
        selectedCommitmentMonth.month + 1,
        0,
      ),
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    for (final vendor in vendorCommitments.values) {
      double remainingCommitment = vendor.commitment;
      if (remainingCommitment <= 0) continue;

      final vendorInvoices = invoiceList
          .where((e) => e.vendorCode == vendor.vendorCode)
          .toList();

      vendorInvoices.sort((a, b) {
        final aDate = _tryParseDate(dateFormat, a.dueon);
        final bDate = _tryParseDate(dateFormat, b.dueon);
        return aDate.compareTo(bDate);
      });

      for (final invoice in vendorInvoices) {
        if (remainingCommitment <= 0) break;

        final balance = _invoiceBalance(invoice);
        if (balance <= 0) continue;

        final allocated = remainingCommitment > balance
            ? balance
            : remainingCommitment;

        selectedInvoices.add({
          'InvoiceNo': invoice.documentNumber,
          'InvoiceIssues': "",
          'InvoiceExpPayDate': expectedPaymentDate,
          'InvoiceExpPayRemarks': "",
          'InvoiceOtherRemarks': "",
          'InvoiceCommitments': allocated,
        });

        remainingCommitment -= allocated;
      }
    }

    return selectedInvoices;
  }

  Future<bool> submitVendorCommitments() async {
    selectedInvoices = generateVendorSAPCommitments();

    final leadmaster = {
      'SalesCommentUpdate': selectedInvoices,
      "sapToken": DataManager.readSapToken(),
    };
    const apiUrl = '${ApiHelper.baseUrl}CRMPurchaseCommentsUpdate';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(leadmaster),
        headers: headerss,
      );
      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      if (responseJson["statusCode"] == 1) {
        await saveVendorCommitment();
        resetVendorWiseGrid();
        const snackBar = SnackBar(
          duration: Duration(seconds: 1),
          content: Text(
            'Saved Successfully...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return true;
      } else {
        const snackBar = SnackBar(
          content: Text('Vendor payment commitment updation failed'),
        );
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return false;
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return false;
    }
  }

  List<Map<String, dynamic>> generateVendorCommitmentSaveData() {
    return vendorSummaryList.map((vendor) {
      final commitment = vendorCommitments[vendor.vendorCode];
      return {
        "VendorCode": vendor.vendorCode,
        "VendorName": vendor.vendorName,
        "CommitmentMonth": selectedCommitmentMonth.month,
        "CommitmentYear": selectedCommitmentMonth.year,
        "Outstanding": vendor.totalOutstanding,
        "Commitment": commitment?.commitment ?? 0,
      };
    }).toList();
  }

  Future<void> saveVendorCommitment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName');
      final userID = prefs.getString('userId') ?? '';
      final userJwtToken = prefs.getString('userJwtToken') ?? '';
      final userMailID = prefs.getString('userMailID') ?? '';
      final data = generateVendorCommitmentSaveData();
      final payload = {
        'UserID': userID,
        'UserJwtToken': userJwtToken,
        'UsermailID': userMailID,
        "userName": userName,
        "data": data,
      };
      await http.post(
        Uri.parse("${ApiHelper.baseUrl}SaveVendorMonthlyCommitment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadSavedVendorCommitment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userID = prefs.getString('userId') ?? '';
      final userJwtToken = prefs.getString('userJwtToken') ?? '';
      final userMailID = prefs.getString('userMailID') ?? '';
      final body = {
        'UserID': userID,
        'UserJwtToken': userJwtToken,
        'UsermailID': userMailID,
        "commitmentMonth": selectedCommitmentMonth.month,
        "commitmentYear": selectedCommitmentMonth.year,
      };
      final response = await http.post(
        Uri.parse("${ApiHelper.baseUrl}GetVendorMonthlyCommitment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final result = jsonDecode(response.body);

      if (result["status"] == true) {
        final data = result["data"] ?? [];

        vendorCommitments.clear();

        for (final item in data) {
          final vendorCode = item["VendorCode"] ?? "";
          final commitment =
              double.tryParse(item["Commitment"].toString()) ?? 0;

          vendorCommitments[vendorCode] = VendorMonthCommitment(
            vendorCode: vendorCode,
            commitment: commitment,
          );

          getVendorCommitmentController(vendorCode).text = commitment == 0
              ? ""
              : commitment.toString();

          for (final summary in vendorSummaryList) {
            if (summary.vendorCode == vendorCode) {
              summary.totalCommitment = commitment;
              break;
            }
          }
        }

        if (!mounted) return;

        setState(() {});
      }
    } catch (e) {
      debugPrint("loadSavedVendorCommitment Error : $e");
    }
  }

  void clearVariables() {
    setState(() {
      _dateController.clear();
      remarksController.clear();
      paymentRemarksController.clear();
      resetSelection();
      customerController.clear();
    });
  }

  Future<void> generateVendorPaymentExcel(ReceivablesAgingList list) async {
    await reportService.generateExcel(
      sheetName: 'VendorPayment',
      headers: ['Ageing Group', 'Ageing Group Total'],
      rows: list.agingData
          .map((e) => [e.agingGroup, e.agingGroupTotal])
          .toList(),
      fileName: 'vendor_payment_analysis.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Finance - Vendor Payment Analysis',
    );
  }

  Future<void> generateVendorPaymentPDF(ReceivablesAgingList list) async {
    await reportService.generatePDF(
      title: 'Vendor Payment',
      headers: ['Ageing Group', 'Ageing Group Total'],
      rows: list.agingData
          .map((e) => [e.agingGroup, e.agingGroupTotal])
          .toList(),
      fileName: 'vendor_payment_analysis.pdf',
      amountColumns: [2],
    );
  }

  bool get _allSelected {
    // true if there's at least one invoice, and every filtered checkbox is true
    return collectionCheckList.isNotEmpty &&
        collectionCheckList.every((checked) => checked);
  }

  void resetSelection() {
    collectionCheckList = List.filled(invoiceList.length, false);
    selectedInvoiceList.clear();
    totalValue = 0;
    valueController.text = "0.00";
    remainingCommitment = 0;
  }

  void _toggleSelectAll(bool? selectAll) {
    if (selectAll == null) return;

    setState(() {
      for (var i = 0; i < collectionCheckList.length; i++) {
        collectionCheckList[i] = selectAll;
        if (!selectAll) {
          invoiceList[i].commitment = "0";
        }
      }

      _refreshSelectedInvoiceTotal();
      _applyCommitmentDistribution();
    });
  }

  void distributeCommitment() {
    applyCommitmentDistribution();
  }

  Future<void> _loadVendorPaymentProjection() async {
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Pre-filter once
    final customerTargetList = target.where((t) {
      final date = dateFormat.parse(t.postingDate);
      return date.isAtMost(currentMonthToDate!);
    });

    final currentMonthActualPayable = modeOfPayment.where((t) {
      final date = dateFormat.parse(t.postingDate);
      return date.isAtLeast(currentMonthFromDate!) &&
          date.isAtMost(currentMonthToDate!);
    });

    // Pre-group actual payable by vendor (O(n))
    final Map<String, double> actualPayableMap = {};
    for (var item in currentMonthActualPayable) {
      actualPayableMap.update(
        item.vendorName,
        (val) => val + (double.tryParse(item.total) ?? 0),
        ifAbsent: () => double.tryParse(item.total) ?? 0,
      );
    }

    // Group target data by vendorCode
    final Map<String, VendorsPaymentProjectionData> vendorMap = {};

    for (var item in customerTargetList) {
      final vendorCode = item.vendorCode;

      final entry = vendorMap.putIfAbsent(
        vendorCode,
        () => VendorsPaymentProjectionData(
          vendorName: item.vendorName,
          vendorCode: vendorCode,
          balanceDue: 0,
          a0to30: 0,
          a31to60: 0,
          a61to90: 0,
          a90to180: 0,
          a180above: 0,
          commitment: 0,
          actualPayable: 0,
        ),
      );

      final balance = double.tryParse(item.balance) ?? 0;
      final commitment = double.tryParse(item.commitment) ?? 0;
      final overDueDays =
          int.tryParse(item.dueDays.replaceAll(' Days', '')) ?? 0;

      entry.balanceDue += balance;
      entry.commitment = commitment;

      if (overDueDays <= 30) {
        entry.a0to30 += double.tryParse(item.a0to30Days) ?? 0;
      } else if (overDueDays <= 60) {
        entry.a31to60 += double.tryParse(item.a31to60Days) ?? 0;
      } else if (overDueDays <= 90) {
        entry.a61to90 += double.tryParse(item.a61to90Days) ?? 0;
      } else if (overDueDays <= 180) {
        entry.a90to180 += double.tryParse(item.a91to180Days) ?? 0;
      } else {
        entry.a180above += double.tryParse(item.a181Days) ?? 0;
      }
    }

    // Attach actual payable (O(n))
    for (var entry in vendorMap.values) {
      entry.actualPayable = actualPayableMap[entry.vendorName] ?? 0;
    }

    final vendorWiseData = vendorMap.values.toList()
      ..sort((a, b) => a.vendorCode.compareTo(b.vendorCode));

    vendorProjectionList = VendorsPaymentProjectionList(
      vendorData: vendorWiseData,
    );
  }

  Future<void> generateVendorPaymentProjectionExcel() async {
    await reportService.generateExcel(
      sheetName: 'VendorPaymentProjection',
      headers: [
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
      ],
      rows: vendorProjectionList.vendorData
          .map(
            (e) => [
              e.vendorCode,
              e.vendorName,
              e.balanceDue,
              e.a0to30,
              e.a31to60,
              e.a61to90,
              e.a90to180,
              e.a180above,
              e.commitment,
              e.actualPayable,
            ],
          )
          .toList(),
      fileName: 'vendor_payment_projection.xlsx',
      amountColumns: [3, 4, 5, 6, 7, 8, 9, 10],
      addTotalRow: true,
      reportTitle: 'Finance - Vendor Payment Projection',
    );
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  DateTime _tryParseDate(DateFormat formatter, String value) {
    try {
      return formatter.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<void> removeFilter() async {
    clearVariables();
    LoadDates();
    allCategoriesState.forEach((category, options) {
      options.updateAll((key, value) => false);
    });
    await loadData("");
  }

  Future<void> toggleCheckbox() async {
    setState(() {
      chartDataLoaded = false;
    });
    await loadData("");
    if (!mounted) return;
    setState(() {
      chartDataLoaded = true;
    });
  }

  String monthName(int month) {
    const months = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return months[month];
  }

  void filterVendorGrid(String value) {
    if (value.trim().isEmpty) {
      filteredVendorSummaryList = List.from(vendorSummaryList);
    } else {
      filteredVendorSummaryList = vendorSummaryList.where((e) {
        return e.vendorName.toLowerCase().contains(value.toLowerCase());
      }).toList();
    }

    setState(() {});
  }

  TextEditingController getVendorCommitmentController(String vendorCode) {
    if (!vendorCommitmentControllers.containsKey(vendorCode)) {
      vendorCommitmentControllers[vendorCode] = TextEditingController();
    }

    return vendorCommitmentControllers[vendorCode]!;
  }

  void resetVendorWiseGrid() {
    for (final controller in vendorCommitmentControllers.values) {
      controller.dispose();
    }

    vendorCommitmentControllers.clear();
    vendorCommitments.clear();
    for (final summary in vendorSummaryList) {
      summary.totalCommitment = 0;
    }
    vendorSearchController.clear();
    filteredVendorSummaryList = List.from(vendorSummaryList);
  }

  @override
  void initState() {
    _focusInvoice = FocusNode();
    loadDataFuture = loadData("");
    super.initState();
    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
  }

  @override
  void dispose() {
    for (final controller in vendorCommitmentControllers.values) {
      controller.dispose();
    }
    vendorSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      deviceOrientation = "Portrait";
    } else {
      deviceOrientation = "Landscape";
    }
    final screenHeight = MediaQuery.of(context).size.height;
    double containerDropDownHeight = 0;
    double containerHeight = 0;

    if (deviceOrientation == "Portrait") {
      containerDropDownHeight = screenHeight * 0.06;
      containerHeight = screenHeight * 0.06;
    } else {
      containerDropDownHeight = screenHeight * 0.12;
    }
    if (!chartDataLoaded) {
      return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            buildViewToggle(),
            const SizedBox(height: 180),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    if (selectedViewType == VendorPaymentViewType.vendorWise) {
      return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            buildViewToggle(),
            const SizedBox(height: 15),
            buildVendorWiseWidget(),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Row(
          //       children: [
          //         const SizedBox(
          //           width: 15,
          //         ),
          //         dateFilterFlag
          //             ? Text(
          //             "${formatDateString(fromDateFilter!)} - ${formatDateString(toDateFilter!)}")
          //             : Text(
          //             "${formatDateString(fiscalYearStartDate!)} - ${formatDateString(currentDate!)}"),
          //       ],
          //     ),
          //     Row(
          //       children: [
          //         IconButton(
          //           onPressed: () {
          //             showFilterBottomSheet(context);
          //           },
          //           icon: const Icon(Icons.settings),
          //         ),
          //       ],
          //     ),
          //   ],
          // ),
          const SizedBox(height: 10),
          buildViewToggle(),
          kIsWeb ? const SizedBox(height: 10) : const SizedBox(height: 0),
          kIsWeb
              ? RawAutocomplete<InvoiceCustomers>(
                  textEditingController: customerController,
                  focusNode: _focusInvoice,
                  optionsBuilder: (TextEditingValue val) {
                    return customers.where((InvoiceCustomers option) {
                      return option.customerName.toLowerCase().contains(
                        val.text.toLowerCase(),
                      );
                    });
                  },
                  displayStringForOption: (InvoiceCustomers option) =>
                      option.customerName,
                  fieldViewBuilder:
                      (
                        context,
                        textEditingController,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onSubmitted: (value) => onFieldSubmitted(),
                          decoration: InputDecoration(
                            labelText: 'Enter Vendor Name',
                            labelStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8F8F8F),
                            ),
                            suffixIcon: IconButton(
                              icon: customerController.text == ""
                                  ? const Icon(
                                      Icons.search,
                                      color: Color(0xff2ca9df),
                                    )
                                  : const Icon(Icons.clear),
                              onPressed: () {
                                _runFilterWithLoader(() {
                                  _clearVendorFilter();
                                });
                              },
                            ),
                          ),
                        );
                      },
                  onSelected: (InvoiceCustomers value) {
                    customerController.text = value.customerName;
                    _runFilterWithLoader(() {
                      selectedDistributorName = value.customerName;
                      selectedDistributorId = value.customerCode;
                      _applyInvoiceFilters();
                    });
                  },
                  optionsViewBuilder:
                      (
                        BuildContext context,
                        void Function(InvoiceCustomers) onSelected,
                        Iterable<InvoiceCustomers> options,
                      ) {
                        return Material(
                          elevation: 4.0,
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              physics: const ClampingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final InvoiceCustomers option = options
                                    .elementAt(index);
                                return GestureDetector(
                                  onTap: () {
                                    onSelected(option);
                                  },
                                  child: ListTile(
                                    title: Text(option.customerName),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                )
              : Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 32.0,
                  ),
                  child: SizedBox(
                    height: deviceOrientation == "Portrait"
                        ? containerHeight
                        : containerDropDownHeight / 1.5,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AsyncAutocomplete<InvoiceCustomers>(
                            onChanged: (s) {
                              setState(() {
                                customerController.text == s;
                              });
                            },
                            onSaved: (s) {
                              setState(() {
                                customerController.text == s;
                              });
                            },
                            maxListHeight: deviceOrientation == "Portrait"
                                ? 370
                                : 220,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.only(
                                left: 0,
                                right: 30,
                                top: 0,
                                bottom: 0,
                              ),
                              border: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              hintText: 'Account Name',
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF8F8F8F),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors
                                      .blue, // Set your desired focus color
                                ),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                            ),
                            controller: customerController,
                            inputKey: distributorKey,
                            onTapItem: (InvoiceCustomers distributor) async {
                              await _runFilterWithLoader(() {
                                customerController.text =
                                    distributor.customerName;
                                selectedDistributorId =
                                    distributor.customerCode;
                                selectedDistributorName =
                                    distributor.customerName;
                                _applyInvoiceFilters();
                              });
                            },
                            suggestionBuilder: (data) =>
                                ListTile(title: Text(data.customerName)),
                            asyncSuggestions: (searchValue) =>
                                getDistributor(searchValue),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: -1,
                          bottom: 2,
                          child: Visibility(
                            child: SizedBox(
                              child: GestureDetector(
                                onTap: () {
                                  _runFilterWithLoader(() {
                                    _clearVendorFilter();
                                  });
                                },
                                child: customerController.text == ""
                                    ? Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.transparent,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.only(
                                            top: 14,
                                            right: 2,
                                          ),
                                          child: Icon(
                                            Icons.search,
                                            color: Color(0xff2ca9df),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.transparent,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.only(
                                            top: 14,
                                            right: 2,
                                          ),
                                          child: Icon(
                                            Icons.cancel_outlined,
                                            color: Color(0xff2ca9df),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          kIsWeb ? const SizedBox(height: 25) : const SizedBox(height: 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 16.0, left: 16.0),
                child: Text(
                  "Pending Invoice-Payment Remark",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
                              generateVendorPaymentProjectionExcel();
                            });
                          },
                          child: const Text(
                            "Download Vendor Payment Projection",
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 400,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(20),
                        child: Table(
                          defaultColumnWidth: const FixedColumnWidth(175.0),
                          border: TableBorder.all(
                            color: Colors.black,
                            style: BorderStyle.solid,
                            width: 0.5,
                          ),
                          children: [
                            TableRow(
                              children: [
                                Container(
                                  height: 50,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Transform.scale(
                                        scale: .7,
                                        child: Checkbox(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              2.0,
                                            ),
                                          ),
                                          side:
                                              WidgetStateBorderSide.resolveWith(
                                                (states) => const BorderSide(
                                                  width: 1.0,
                                                  color: Color(0xFF8F8F8F),
                                                ),
                                              ),
                                          value: _allSelected,
                                          onChanged: _toggleSelectAll,
                                        ),
                                      ),
                                      const Text(
                                        'Invoice No/Date',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        'Vendor Name',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        'Value',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        'Status',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        'Payment Issues',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        'Commitment',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        'Payment Date',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        'Payment Remarks',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ...List.generate(invoiceList.length, (i) {
                              final balance =
                                  double.tryParse(
                                    invoiceList[i].balance,
                                  )?.abs() ??
                                  0;
                              final commitment =
                                  double.tryParse(invoiceList[i].commitment) ??
                                  0;
                              final isPartial =
                                  commitment > 0 && commitment < balance;
                              final isFull =
                                  commitment >= balance && balance > 0;

                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isFull
                                      ? const Color(0xFFD4EDDA)
                                      : isPartial
                                      ? const Color(0xFFFFF3CD)
                                      : null,
                                ),
                                children: [
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Transform.scale(
                                            scale: .7,
                                            child: Checkbox(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(2.0),
                                              ),
                                              side:
                                                  WidgetStateBorderSide.resolveWith(
                                                    (states) =>
                                                        const BorderSide(
                                                          width: 1.0,
                                                          color: Color(
                                                            0xFF8F8F8F,
                                                          ),
                                                        ),
                                                  ),
                                              value: collectionCheckList[i],
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  collectionCheckList[i] =
                                                      value ?? false;

                                                  if (!collectionCheckList[i]) {
                                                    invoiceList[i].commitment =
                                                        "0";
                                                  }

                                                  _refreshSelectedInvoiceTotal();
                                                  _applyCommitmentDistribution();
                                                });
                                              },
                                            ),
                                          ),
                                          Text(
                                            "${invoiceList[i].documentNumber}/\n${invoiceList[i].postingDate}",
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        invoiceList[i].vendorName.toString(),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8.0,
                                        right: 8.0,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(balance.toStringAsFixed(2)),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(invoiceList[i].dueDays),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(invoiceList[i].invoiceIssues),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                commitment.toStringAsFixed(2),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              LinearProgressIndicator(
                                                value: balance == 0
                                                    ? 0
                                                    : (commitment / balance)
                                                          .clamp(0, 1),
                                                minHeight: 5,
                                                backgroundColor:
                                                    Colors.grey.shade300,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      isFull
                                                          ? Colors.green
                                                          : isPartial
                                                          ? Colors.orange
                                                          : Colors.grey,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        invoiceList[i].expectedPayment,
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        invoiceList[i].expectedPaymentRemarks,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 20),
              Container(
                color: const Color(0xFFD9D9D9),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    "Total Outstanding - ${formatAmount(collectionAchieved.abs())}",
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0),
            child: Divider(thickness: 2),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 8.0,
              bottom: 16.0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: AbsorbPointer(
                      absorbing: true,
                      child: TextField(
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8F8F8F),
                        ),
                        controller: valueController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          hintText: '0.00 L',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8F8F8F),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Flexible(
                  child: TextField(
                    canRequestFocus: false,
                    style: const TextStyle(color: Color(0xFF8F8F8F)),
                    keyboardType: TextInputType.none,
                    controller: _dateController,
                    decoration: const InputDecoration(
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(left: 20.0),
                        child: Icon(
                          Icons.calendar_today,
                          color: Color(0xffD9D9D9),
                          size: 20,
                        ),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      labelText: 'On',
                      contentPadding: EdgeInsets.only(bottom: 0),
                      labelStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8F8F8F),
                      ),
                    ),
                    onTap: () async {
                      DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        initialEntryMode: DatePickerEntryMode.calendar,
                      );

                      String formattedDateTime = DateFormat('yyyy-MM-dd')
                          .format(
                            DateTime(
                              selectedDate!.year,
                              selectedDate.month,
                              selectedDate.day,
                            ),
                          );
                      _dateController.text = formattedDateTime;
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
            child: SizedBox(
              height: 70,
              width: 400,
              child: Padding(
                padding: const EdgeInsets.only(top: 0),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedModeOfPayment,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xffD9D9D9),
                    size: 30,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedModeOfPayment = newValue!;
                    });
                  },
                  items:
                      <String>[
                        'Credit Note Issues Invoice',
                        'Disputed Issues Invoice',
                        'Legal Issues Invoice',
                        'Payment Outstanding Invoice',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8F8F8F),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 8.0,
              bottom: 16.0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8F8F8F),
                          ),
                          controller: commitmentController,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: 'Commitment',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8F8F8F),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: applyCommitmentDistribution,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2ca9df),
                            ),
                            child: const Text("Apply"),
                          ),
                        ),
                        if (remainingCommitment > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "Remaining not allocated: ${remainingCommitment.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: TextField(
              controller: paymentRemarksController,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF8F8F8F)),
                  borderRadius: BorderRadius.circular(1),
                ),
                hintText: "Payment Remarks",
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8F8F8F),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 1, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: TextField(
              controller: remarksController,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF8F8F8F)),
                  borderRadius: BorderRadius.circular(1),
                ),
                hintText: "Remarks",
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8F8F8F),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 1, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2ca9df),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                onPressed: () async {
                  final saved = await submitCommitments();
                  if (!saved || !mounted) return;
                  showAlertDialog(context);
                  setState(() {
                    resetSelection();
                  });
                },
                child: const SizedBox(
                  width: 400,
                  child: Center(
                    child: Text(
                      "Save",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0),
            child: Divider(thickness: 2),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Tooltip(
                preferBelow: false,
                richMessage: WidgetSpan(
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Text("Target : $collectionAgingGoalStr"),
                          Text(
                            "Achieved : ${formatAmount(collectionAchieved)}",
                          ),
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
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                showDuration: const Duration(seconds: 7),
                triggerMode: TooltipTriggerMode.tap,
                child: Padding(
                  padding: const EdgeInsets.only(left: 0.0, top: 32),
                  child: CircularPercentIndicator(
                    arcType: ArcType.HALF,
                    radius: 80.0,
                    lineWidth: 35.0,
                    animation: true,
                    percent: collectionPercentage / 100,
                    center: Column(
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          "$collectionPercentage%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          formatAmount(collectionAchieved.abs()),
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                          ),
                        ),
                        const Center(
                          child: Text(
                            "Payment Progress (%)",
                            style: TextStyle(
                              fontSize: 10.0,
                              color: Colors.black,
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
              Tooltip(
                preferBelow: false,
                richMessage: WidgetSpan(
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Text(
                            "0-30 : ${formatAmount(receivablesAgingList.agingData[0].agingGroupTotal)}",
                          ),
                          Text(
                            "31-60 : ${formatAmount(receivablesAgingList.agingData[1].agingGroupTotal)}",
                          ),
                          Text(
                            "61-90 : ${formatAmount(receivablesAgingList.agingData[2].agingGroupTotal)}",
                          ),
                          Text(
                            "90+ : ${formatAmount(receivablesAgingList.agingData[3].agingGroupTotal)}",
                          ),
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
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                showDuration: const Duration(seconds: 7),
                triggerMode: TooltipTriggerMode.tap,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 0.0, right: 24),
                      child: SizedBox(
                        height: 100,
                        width: 100,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        touchedIndex = -1;
                                        return;
                                      }
                                      touchedIndex = pieTouchResponse
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
                    const SizedBox(height: 40),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 8,
                                width: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 8,
                                width: 16,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "0-30",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "31-60",
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  height: 8,
                                  width: 16,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  height: 8,
                                  width: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "61-90",
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "90+",
                                style: TextStyle(fontSize: 10),
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
                    "Payables Aging",
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
                            generateVendorPaymentExcel(receivablesAgingList);
                          },
                          child: const Text("Download Excel"),
                        ),
                        PopupMenuItem(
                          onTap: () {
                            generateVendorPaymentPDF(receivablesAgingList);
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
        ],
      ),
    );
  }

  Widget buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (selectedViewType == VendorPaymentViewType.vendorWise) {
                  return;
                }
                setState(() {
                  selectedViewType = VendorPaymentViewType.vendorWise;
                  chartDataLoaded = false;
                });
                await loadData("");
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: selectedViewType == VendorPaymentViewType.vendorWise
                      ? const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 110, 218, 209),
                            Color(0xff2ca9df),
                          ],
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      color:
                          selectedViewType == VendorPaymentViewType.vendorWise
                          ? Colors.white
                          : Colors.black54,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Vendor Wise",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            selectedViewType == VendorPaymentViewType.vendorWise
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (selectedViewType == VendorPaymentViewType.billWise) {
                  return;
                }
                setState(() {
                  selectedViewType = VendorPaymentViewType.billWise;
                  chartDataLoaded = false;
                });
                await loadData("");
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: selectedViewType == VendorPaymentViewType.billWise
                      ? const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 110, 218, 209),
                            Color(0xff2ca9df),
                          ],
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: selectedViewType == VendorPaymentViewType.billWise
                          ? Colors.white
                          : Colors.black54,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Bill Wise",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            selectedViewType == VendorPaymentViewType.billWise
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMonthSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 110, 218, 209), Color(0xff2ca9df)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final picked = await showMonthPicker(
            context: context,
            initialDate: selectedCommitmentMonth,
            firstDate: DateTime(2023),
            lastDate: DateTime(2100),
          );

          if (picked != null) {
            resetVendorWiseGrid();
            setState(() {
              selectedCommitmentMonth = picked;
              chartDataLoaded = false;
            });
            await loadData("");
          }
        },
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${monthName(selectedCommitmentMonth.month)} "
                "${selectedCommitmentMonth.year}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.edit_calendar_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget buildVendorGridHeader() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xffe8f1ff),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          buildVendorSearchHeader(),
          buildVendorHeaderCell("Balance", 140),
          buildVendorHeaderCell("Commitment", 150),
          buildVendorHeaderCell(" +/- ", 140),
        ],
      ),
    );
  }

  Widget buildVendorSearchHeader() {
    return Container(
      width: 360,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: TextField(
        controller: vendorSearchController,
        onChanged: filterVendorGrid,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: "Search Vendor",
          prefixIcon: const Icon(Icons.search, size: 18),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget buildVendorHeaderCell(String title, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  Widget buildVendorDataCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget buildVendorCommitmentCell(VendorCommitmentSummary vendor) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: TextField(
        controller: getVendorCommitmentController(vendor.vendorCode),
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onChanged: (value) {
          final amount = double.tryParse(value) ?? 0;
          vendorCommitments[vendor.vendorCode] = VendorMonthCommitment(
            vendorCode: vendor.vendorCode,
            commitment: amount,
          );
          vendor.totalCommitment = amount;
          setState(() {});
        },
      ),
    );
  }

  Widget buildVendorGridRow(VendorCommitmentSummary vendor) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: vendor.totalCommitment > vendor.totalOutstanding
            ? Colors.red.shade50
            : null,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          buildVendorDataCell(vendor.vendorName, 360),
          buildVendorDataCell(formatAmount(vendor.totalOutstanding), 140),
          buildVendorCommitmentCell(vendor),
          buildVendorDataCell(
            formatAmount(vendor.totalOutstanding - vendor.totalCommitment),
            140,
          ),
        ],
      ),
    );
  }

  Widget buildVendorWiseWidget() {
    final screenHeight = MediaQuery.of(context).size.height;
    final double tableHeight = (screenHeight - 430).clamp(300.0, 900.0);
    return Column(
      children: [
        buildMonthSelector(),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 792,
              child: Column(
                children: [
                  buildVendorGridHeader(),
                  SizedBox(
                    height: tableHeight,
                    child: ListView.builder(
                      itemCount: filteredVendorSummaryList.length,
                      itemBuilder: (context, index) {
                        return buildVendorGridRow(
                          filteredVendorSummaryList[index],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                final invalidVendors = vendorSummaryList.where((e) {
                  return e.totalCommitment > e.totalOutstanding;
                }).toList();
                if (invalidVendors.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        "${invalidVendors.length} "
                        "vendor commitments exceeded outstanding",
                      ),
                    ),
                  );
                  return;
                }
                final hasCommitments = vendorSummaryList.any(
                  (e) => e.totalCommitment > 0,
                );
                if (!hasCommitments) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter commitment to save")),
                  );
                  return;
                }
                final saved = await submitVendorCommitments();
                if (!saved || !mounted) return;
                showAlertDialog(context);
                setState(() {});
              },
              icon: const Icon(Icons.save),
              label: const Text("Save Commitments"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                backgroundColor: const Color(0xff2ca9df),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
                    'Payables\n',
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

  showAlertDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () {
        loadDataFuture = loadData("");
        Navigator.pop(context);
        clearVariables();
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Invoices Updated!"),
      content: const Text("Selected Invoices have been updated"),
      actions: [okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
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

                                      Navigator.pop(context);

                                      selectedSalesData = selectedFilterOptions;

                                      savedFinanceReceivablesOptionsTemp =
                                          savedFinanceReceivablesOptions;

                                      fromFilter = false;

                                      await toggleCheckbox();
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
                                    onPressed: () async {
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        chartDataLoaded = false;
                                      });
                                      Navigator.pop(context);
                                      loadDataFuture = removeFilter();
                                      await loadDataFuture;
                                      if (!mounted) return;
                                      setState(() {
                                        chartDataLoaded = true;
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

Widget headerCell(String text) {
  return Container(
    width: 175,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(border: Border.all(color: Colors.black)),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );
}

Widget dataCell(String text) {
  return Container(
    width: 175,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(border: Border.all(color: Colors.black)),
    child: Text(text),
  );
}
