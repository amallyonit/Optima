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
  DebtorsAgingList invoice;
  bool isChecked;

  InvoiceWrapper({required this.invoice, required this.isChecked});
}

ReceivablesAgingList receivablesAgingList = ReceivablesAgingList(agingData: []);

String deviceOrientation = "";
final TextEditingController customerController = TextEditingController();
final TextEditingController asmController = TextEditingController();
final TextEditingController rsmController = TextEditingController();
final TextEditingController valueController = TextEditingController();
late Future<void> loadDataFuture;

bool disableSave = false;

double totalValue = 0.0;
List<Distributor> dList = [];
List<Users> usersList = [];
List<Users> childUsers = [];
bool noUserList = false;
List<CollectionList> collection = [];
List<DebtorsAgingList> target = [];
List<DebtorsAgingList> invoiceList = [];
List<DebtorsAgingList> invoiceListTemp = [];
List<DebtorsAgingList> selectedInvoiceList = [];
List<Users> usersListForFilter = [];
List<InvoiceCustomers> customers = [];
List<InvoiceCustomers> customersTemp = [];
List<UsersForSearch> asmList = [];
List<UsersForSearch> rsmList = [];
List<Map<String, dynamic>> userList = [];
List<MyNode> nodes = [];
double remainingCommitment = 0;

class CustomerCollectionAnalysis extends StatefulWidget {
  const CustomerCollectionAnalysis({super.key});

  @override
  State<CustomerCollectionAnalysis> createState() =>
      _CustomerCollectionAnalysisState();
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
      value: categoryData.agingPercentage,
      title: '${categoryData.agingPercentage.toStringAsFixed(2)} %',
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
double totalOutstanding = 0;

List<bool> collectionCheckList = List.generate(
  invoiceList.length,
  (index) => true,
);

bool chartDataLoadedCustomerCollection = false;
String? selectedModeOfPayment = "Payment Outstanding Invoice";

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

class CollectionAnalysisCustomerDashboardTargetProvider with ChangeNotifier {
  List<DebtorsAgingList> _targetList = [];
  List<DebtorsAgingList> get targetList => _targetList;
  void updateTargetList(List<DebtorsAgingList> newTargetList) {
    _targetList = newTargetList;
    notifyListeners();
  }
}

class _CustomerCollectionAnalysisState
    extends State<CustomerCollectionAnalysis> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController paymentRemarksController =
      TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController commitmentController = TextEditingController();
  String? selectedModeOfPayment = "Payment Outstanding Invoice";
  late FocusNode _focus;
  late FocusNode _focusRSM;
  late FocusNode _focusInvoice;

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
  var rsmKey = GlobalKey();
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

  Future<List<InvoiceCustomers>> getCustomer(String search) async {
    setState(() {});

    final searchText = search.toLowerCase();
    final asmFilter = asmController.text;
    final rsmFilter = rsmController.text;

    if (searchText.isEmpty && asmFilter.isEmpty && rsmFilter.isEmpty) {
      customers = customersTemp;
    }

    // If nothing to filter on, return the full list immediately:
    if (searchText.isEmpty && asmFilter.isEmpty && rsmFilter.isEmpty) {
      return customers;
    }

    // Otherwise apply your combined filters:
    return customers.where((c) {
      final matchesSearch = searchText.isEmpty
          ? true
          : c.customerName.toLowerCase().startsWith(searchText);

      final matchesAsm = asmFilter.isEmpty
          ? true
          : (c.salesManager ?? '').toLowerCase() == asmFilter.toLowerCase();

      final matchesRsm = rsmFilter.isEmpty
          ? true
          : (c.regionalManager ?? '').toLowerCase() == rsmFilter.toLowerCase();

      return matchesSearch && matchesAsm && matchesRsm;
    }).toList();
  }

  Future<List<UsersForSearch>> getASM(String search) async {
    asmList = invoiceList
        .map(
          (item) => UsersForSearch(
            menuName: item.salesManager,
            menuId: item.salesManager,
          ),
        )
        .toList();

    asmList = asmList.toSet().toList();
    List<UsersForSearch> filteredList = asmList
        .where(
          (element) =>
              element.menuName.toLowerCase().startsWith(search.toLowerCase()),
        )
        .toList();

    return filteredList;
  }

  Future<List<UsersForSearch>> getRSM(String search) async {
    List<UsersForSearch> filteredList = rsmList
        .where(
          (element) =>
              element.menuName.toLowerCase().startsWith(search.toLowerCase()),
        )
        .toList();

    return filteredList;
  }

  void sortInvoicesByDate() {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');

    List<InvoiceWrapper> combinedList = List.generate(
      invoiceList.length,
      (i) => InvoiceWrapper(
        invoice: invoiceList[i],
        isChecked: collectionCheckList[i],
      ),
    );

    // Sort by due date (same logic as distribution)
    combinedList.sort((a, b) {
      final dateA = formatter.parse(a.invoice.dueon);
      final dateB = formatter.parse(b.invoice.dueon);
      return dateA.compareTo(dateB); // oldest first
    });

    // Reassign back
    invoiceList = combinedList.map((e) => e.invoice).toList();
    collectionCheckList = combinedList.map((e) => e.isChecked).toList();

    // Rebuild selected list
    selectedInvoiceList = [];
    for (int i = 0; i < invoiceList.length; i++) {
      if (collectionCheckList[i]) {
        selectedInvoiceList.add(invoiceList[i]);
      }
    }
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
    LoadDates();
    await _loadUserList(
      userId,
      userJwtToken,
      userMailID,
      int.tryParse(userLevel) ?? 0,
    );
    await _loadCollectionTarget(userName, userLevel);
    await _loadReceivablesAgingData(
      0,
      "",
      "",
      "",
      ""
          "",
      "",
    );
    collectionCheckList = List<bool>.filled(invoiceList.length, true);
    selectedInvoiceList = List.from(invoiceList);
    for (var i = 0; i < collectionCheckList.length; i++) {
      totalOutstanding += double.parse(invoiceList[i].balance).abs();
    }
    if (!mounted) return;
    setState(() {
      chartDataLoadedCustomerCollection = true;
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

      collectionAgingGoal += agingData.agingGroupTotal;
    }

    collectionAgingGoal += collectionAchieved;
    collectionAgingGoalStr = formatAmount(collectionAgingGoal);

    if (collectionAgingGoal == 0) {
      collectionPercentage = 0;
    } else {
      collectionPercentage =
          double.tryParse(
            ((collectionAchieved / collectionAgingGoal) * 100).toStringAsFixed(
              2,
            ),
          )?.ceil() ??
          0;
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

  Future<void> _loadCollectionTarget(String userName, String userLevel) async {
    int index = 0;
    const int limit = 10000;

    final List<DebtorsAgingList> targetList = [];

    final fromDate = formatDate(
      dateFilterFlag ? fromDateFilter! : fiscalYearStartDate!,
    );
    final toDate = formatDate(dateFilterFlag ? toDateFilter! : currentDate!);

    final sapToken = DataManager.readSapToken();
    final uri = Uri.parse('${ApiHelper.baseUrl}Bicxo_DebtorsAgingList');

    try {
      while (true) {
        final body = jsonEncode({
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": sapToken,
        });

        final response = await http.post(
          uri,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: body,
        );

        if (response.statusCode != 200) break;

        final responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'];

        if (data == null || data.isEmpty) break;

        final newList = (data as List)
            .map((item) => DebtorsAgingList.fromJson(item))
            .toList();

        targetList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      // ---- FILTER ONCE ----
      final filteredTarget = targetList
          .where((e) => e.salesManager.isNotEmpty)
          .toList();

      // ---- SINGLE PASS CALCULATION ----
      final DateFormat formatter = DateFormat('dd/MM/yyyy');

      double sum = 0;
      final List<DebtorsAgingList> invoices = [];

      final Set<InvoiceCustomers> customerSet = {};
      final Set<UsersForSearch> asmSet = {};
      final Set<UsersForSearch> rsmSet = {};

      for (final item in filteredTarget) {
        final dueDate = formatter.parse(item.dueon);

        if (dueDate.isAtMost(currentMonthToDate!)) {
          final balance = double.tryParse(item.balance) ?? 0;
          sum += balance;

          if (item.documentType == "Invoice") {
            invoices.add(item);

            customerSet.add(
              InvoiceCustomers(
                customerName: item.customerName,
                customerCode: item.customerCode,
                salesManager: item.salesManager,
                regionalManager: item.regionalManager,
              ),
            );

            asmSet.add(
              UsersForSearch(
                menuName: item.salesManager,
                menuId: item.salesManager,
              ),
            );

            rsmSet.add(
              UsersForSearch(
                menuName: item.regionalManager,
                menuId: item.regionalManager,
              ),
            );
          }
        }
      }

      // ---- STATE UPDATE (MINIMAL WORK INSIDE) ----
      setState(() {
        context
            .read<CollectionAnalysisCustomerDashboardTargetProvider>()
            .updateTargetList(targetList);

        target = filteredTarget;

        collectionAchieved = sum;
        collectionAchievedStr = sum.toString();

        invoiceList = invoices;
        invoiceListTemp = invoices;

        sortInvoicesByDate();
        collectionCheckList = List<bool>.filled(invoiceList.length, true);
        selectedInvoiceList = List.from(invoiceList);

        customers = customerSet.toList();
        customersTemp = customerSet.toList();
        asmList = asmSet.toList();
        rsmList = rsmSet.toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Something went wrong'),
        ),
      );
    }
  }

  void _findCollectionTarget() {
    double sum = 0;
    var currentMonthTarget = invoiceList.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
      return dueon.isAtMost(currentMonthToDate!);
    });
    for (var target in currentMonthTarget.toList()) {
      double balance = double.tryParse(target.balance) ?? 0;
      sum += balance;
    }
    collectionAchieved = sum;
    valueController.text = collectionAchieved.toStringAsFixed(0);
  }

  void applyCommitmentDistribution() {
    double remaining = double.tryParse(commitmentController.text) ?? 0;

    if (remaining <= 0) return;

    sortInvoicesByDate();
    setState(() {
      // 1. Reset all commitments
      for (var item in invoiceList) {
        item.commitment = "0";
      }

      // 2. Sort invoices by due date (recommended)
      final indexedList = List.generate(invoiceList.length, (i) => i);

      indexedList.sort((a, b) {
        final dateA = DateFormat('dd/MM/yyyy').parse(invoiceList[a].dueon);
        final dateB = DateFormat('dd/MM/yyyy').parse(invoiceList[b].dueon);
        return dateA.compareTo(dateB); // oldest first
      });

      // 3. Distribute only to checked rows
      for (final i in indexedList) {
        if (!collectionCheckList[i]) continue;

        double balance = double.tryParse(invoiceList[i].balance)?.abs() ?? 0;

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
    });
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

  Future<void> submitLeads() async {
    String date = _dateController.text;

    selectedInvoices = selectedInvoiceList
        .whereType<DebtorsAgingList>()
        .map(
          (DebtorsAgingList item) => {
            'InvoiceNo': item.documentNumber,
            'InvoiceIssues': selectedModeOfPayment,
            'InvoiceExpPayDate': date,
            'InvoiceExpPayRemarks': paymentRemarksController.text,
            'InvoiceOtherRemarks': remarksController.text,
            'InvoiceCommitments': commitmentController.text,
          },
        )
        .toList();

    final leadmaster = {
      'SalesCommentUpdate': selectedInvoices,
      "sapToken": DataManager.readSapToken(),
    };
    const apiUrl = '${ApiHelper.baseUrl}CRMSalesCommentsUpdate';
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        const snackBar = SnackBar(
          content: Text('Collection comment updation failed'),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void clearVariables() {
    setState(() {
      _dateController.clear();
      remarksController.clear();
      commitmentController.clear();
      paymentRemarksController.clear();
      collectionCheckList = List.generate(
        collectionCheckList.length,
        (_) => false,
      );
      selectedInvoiceList.clear();
      valueController.clear();
      customerController.clear();
    });
  }

  Future<void> generateCustomerCollectionExcel(
    ReceivablesAgingList list,
  ) async {
    await reportService.generateExcel(
      sheetName: 'CustomerCollection',
      headers: ['Ageing Group', 'Ageing Group Total'],
      rows: list.agingData
          .map((e) => [e.agingGroup, e.agingGroupTotal])
          .toList(),
      fileName: 'customer_collection.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Finance - Customer Collection',
    );
  }

  Future<void> generateCustomerCollectionPDF(ReceivablesAgingList list) async {
    await reportService.generatePDF(
      title: 'Customer Collection',
      headers: ['Ageing Group', 'Ageing Group Total'],
      rows: list.agingData
          .map((e) => [e.agingGroup, e.agingGroupTotal])
          .toList(),
      fileName: 'customer_collection.pdf',
      amountColumns: [2],
    );
  }

  bool get _allSelected {
    // true if there's at least one invoice, and every filtered checkbox is true
    return collectionCheckList.isNotEmpty &&
        collectionCheckList.every((checked) => checked);
  }

  void _toggleSelectAll(bool? selectAll) {
    if (selectAll == null) return;

    setState(() {
      double total = 0.0;
      selectedInvoiceList.clear();

      for (var i = 0; i < collectionCheckList.length; i++) {
        collectionCheckList[i] = selectAll;

        if (selectAll) {
          total += double.parse(invoiceList[i].balance).abs();
          selectedInvoiceList.add(invoiceList[i]);
        }
      }

      valueController.text = selectAll ? total.toStringAsFixed(0) : '0';
    });
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  Future<void> removeFilter() async {
    clearVariables();
    LoadDates();
    allCategoriesState.forEach((category, options) {
      options.updateAll((key, value) => false);
    });
    loadData("");
    chartDataLoadedCustomerCollection = true;
  }

  void toggleCheckbox() {
    setState(() {
      chartDataLoadedCustomerCollection = false;
      loadData("");
      // selectedCheckbox = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focusInvoice = FocusNode();
    _focusRSM = FocusNode();
    loadDataFuture = loadData("");
    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
  }

  @override
  void dispose() {
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
    return chartDataLoadedCustomerCollection == true
        ? SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                kIsWeb
                    ? const SizedBox(height: 10)
                    : const SizedBox(height: 20),
                kIsWeb
                    ? RawAutocomplete<UsersForSearch>(
                        textEditingController: rsmController,
                        focusNode: _focusRSM,
                        optionsBuilder: (TextEditingValue val) {
                          return rsmList.where(
                            (user) => user.menuName.toLowerCase().contains(
                              val.text.toLowerCase(),
                            ),
                          );
                        },
                        displayStringForOption: (UsersForSearch option) =>
                            option.menuName,
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
                                  labelText: 'Enter RSM Name',
                                  labelStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF8F8F8F),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: rsmController.text == ""
                                        ? const Icon(
                                            Icons.search,
                                            color: Color(0xff2ca9df),
                                          )
                                        : const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        selectedDistributorId = "";
                                        selectedDistributorName = "";
                                        rsmController.clear();
                                        asmController.clear();
                                        customerController.clear();
                                        invoiceList = invoiceListTemp;
                                        sortInvoicesByDate();
                                        collectionCheckList = List<bool>.filled(
                                          invoiceList.length,
                                          true,
                                        );
                                        selectedInvoiceList = List.from(
                                          invoiceList,
                                        );
                                        _findCollectionTarget();
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                        onSelected: (UsersForSearch value) {
                          setState(() {
                            rsmController.text = value.menuName;
                            invoiceList = invoiceListTemp
                                .where(
                                  (invoice) =>
                                      invoice.regionalManager == value.menuName,
                                )
                                .toList();
                            sortInvoicesByDate();
                            asmList = invoiceList
                                .map(
                                  (item) => UsersForSearch(
                                    menuName: item.salesManager,
                                    menuId: item.salesManager,
                                  ),
                                )
                                .toList();
                            customers = invoiceList
                                .map(
                                  (item) => InvoiceCustomers(
                                    customerName: item.customerName,
                                    customerCode: item.customerCode,
                                    salesManager: item.salesManager,
                                    regionalManager: item.regionalManager,
                                  ),
                                )
                                .toList();

                            customers = customers.toSet().toList();
                            asmList = asmList.toSet().toList();
                            _findCollectionTarget();
                            collectionCheckList = List<bool>.filled(
                              invoiceList.length,
                              true,
                            );
                            selectedInvoiceList = List.from(invoiceList);
                          });
                        },
                        optionsViewBuilder:
                            (
                              BuildContext context,
                              void Function(UsersForSearch) onSelected,
                              Iterable<UsersForSearch> options,
                            ) {
                              return Material(
                                elevation: 4.0,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    physics: const ClampingScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          final UsersForSearch option = options
                                              .elementAt(index);
                                          return GestureDetector(
                                            onTap: () {
                                              onSelected(option);
                                            },
                                            child: ListTile(
                                              title: Text(option.menuName),
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
                                child: AsyncAutocomplete<UsersForSearch>(
                                  onChanged: (s) {
                                    setState(() {
                                      rsmController.text == s;
                                    });
                                  },
                                  onSaved: (s) {
                                    setState(() {
                                      rsmController.text == s;
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
                                    hintText: 'RSM Name',
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
                                  controller: rsmController,
                                  inputKey: rsmKey,
                                  onTapItem: (UsersForSearch users) async {
                                    setState(() {
                                      rsmController.text = users.menuName;
                                      invoiceList = invoiceList
                                          .where(
                                            (invoice) =>
                                                invoice.regionalManager ==
                                                users.menuName,
                                          )
                                          .toList();
                                      _findCollectionTarget();
                                      asmList = invoiceList
                                          .map(
                                            (item) => UsersForSearch(
                                              menuName: item.salesManager,
                                              menuId: item.salesManager,
                                            ),
                                          )
                                          .toList();
                                      customers = invoiceList
                                          .map(
                                            (item) => InvoiceCustomers(
                                              customerName: item.customerName,
                                              customerCode: item.customerCode,
                                              salesManager: item.salesManager,
                                              regionalManager:
                                                  item.regionalManager,
                                            ),
                                          )
                                          .toList();

                                      customers = customers.toSet().toList();
                                      asmList = asmList.toSet().toList();

                                      collectionCheckList = List<bool>.filled(
                                        invoiceList.length,
                                        true,
                                      );
                                      selectedInvoiceList = List.from(
                                        invoiceList,
                                      );
                                    });
                                  },
                                  suggestionBuilder: (data) =>
                                      ListTile(title: Text(data.menuName)),
                                  asyncSuggestions: (searchValue) =>
                                      getRSM(searchValue),
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
                                        setState(() {
                                          selectedDistributorId = "";
                                          selectedDistributorName = "";
                                          invoiceList = invoiceListTemp;
                                          sortInvoicesByDate();
                                          rsmController.clear();
                                          asmController.clear();
                                          customerController.clear();
                                          collectionCheckList =
                                              List<bool>.filled(
                                                invoiceList.length,
                                                true,
                                              );
                                          selectedInvoiceList = List.from(
                                            invoiceList,
                                          );
                                          _findCollectionTarget();
                                        });
                                      },
                                      child: rsmController.text == ""
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
                kIsWeb
                    ? RawAutocomplete<UsersForSearch>(
                        textEditingController: asmController,
                        focusNode: _focus,
                        optionsBuilder: (TextEditingValue val) {
                          return asmList.where(
                            (user) => user.menuName.toLowerCase().contains(
                              val.text.toLowerCase(),
                            ),
                          );
                        },
                        displayStringForOption: (UsersForSearch option) =>
                            option.menuName,
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
                                  labelText: 'Enter ASM Name',
                                  labelStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF8F8F8F),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: asmController.text == ""
                                        ? const Icon(
                                            Icons.search,
                                            color: Color(0xff2ca9df),
                                          )
                                        : const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        selectedDistributorId = "";
                                        selectedDistributorName = "";
                                        asmController.clear();
                                        customerController.clear();
                                        _findCollectionTarget();
                                        invoiceList = invoiceListTemp;
                                        sortInvoicesByDate();
                                        collectionCheckList = List<bool>.filled(
                                          invoiceList.length,
                                          true,
                                        );
                                        selectedInvoiceList = List.from(
                                          invoiceList,
                                        );
                                        getCustomer("");
                                        getASM("");
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                        onSelected: (UsersForSearch value) {
                          setState(() {
                            asmController.text = value.menuName;
                            invoiceList = invoiceListTemp
                                .where(
                                  (invoice) =>
                                      invoice.salesManager == value.menuName,
                                )
                                .toList();
                            sortInvoicesByDate();
                            customers = invoiceList
                                .map(
                                  (item) => InvoiceCustomers(
                                    customerName: item.customerName,
                                    customerCode: item.customerCode,
                                    salesManager: item.salesManager,
                                    regionalManager: item.regionalManager,
                                  ),
                                )
                                .toList();

                            customers = customers.toSet().toList();

                            _findCollectionTarget();

                            collectionCheckList = List<bool>.filled(
                              invoiceList.length,
                              true,
                            );
                            selectedInvoiceList = List.from(invoiceList);
                          });
                        },
                        optionsViewBuilder:
                            (
                              BuildContext context,
                              void Function(UsersForSearch) onSelected,
                              Iterable<UsersForSearch> options,
                            ) {
                              return Material(
                                elevation: 4.0,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    physics: const ClampingScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          final UsersForSearch option = options
                                              .elementAt(index);
                                          return GestureDetector(
                                            onTap: () {
                                              onSelected(option);
                                            },
                                            child: ListTile(
                                              title: Text(option.menuName),
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
                                child: AsyncAutocomplete<UsersForSearch>(
                                  onChanged: (s) {
                                    setState(() {
                                      asmController.text == s;
                                    });
                                  },
                                  onSaved: (s) {
                                    setState(() {
                                      asmController.text == s;
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
                                    hintText: 'ASM Name',
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
                                  controller: asmController,
                                  inputKey: asmKey,
                                  onTapItem: (UsersForSearch users) async {
                                    setState(() {
                                      asmController.text = users.menuName;
                                      invoiceList = invoiceList
                                          .where(
                                            (invoice) =>
                                                invoice.salesManager ==
                                                users.menuName,
                                          )
                                          .toList();
                                      _findCollectionTarget();
                                      collectionCheckList = List<bool>.filled(
                                        invoiceList.length,
                                        true,
                                      );
                                      selectedInvoiceList = List.from(
                                        invoiceList,
                                      );

                                      customers = invoiceList
                                          .map(
                                            (item) => InvoiceCustomers(
                                              customerName: item.customerName,
                                              customerCode: item.customerCode,
                                              salesManager: item.salesManager,
                                              regionalManager:
                                                  item.regionalManager,
                                            ),
                                          )
                                          .toList();

                                      customers = customers.toSet().toList();
                                    });
                                  },
                                  suggestionBuilder: (data) =>
                                      ListTile(title: Text(data.menuName)),
                                  asyncSuggestions: (searchValue) =>
                                      getASM(searchValue),
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
                                        setState(() {
                                          selectedDistributorId = "";
                                          selectedDistributorName = "";
                                          invoiceList = invoiceListTemp;
                                          sortInvoicesByDate();
                                          asmController.clear();
                                          customerController.clear();
                                          collectionCheckList =
                                              List<bool>.filled(
                                                invoiceList.length,
                                                true,
                                              );
                                          selectedInvoiceList = List.from(
                                            invoiceList,
                                          );
                                          _findCollectionTarget();
                                          getCustomer("");
                                          getASM("");
                                        });
                                      },
                                      child: asmController.text == ""
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
                                  labelText: 'Enter Account Name',
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
                                      setState(() {
                                        selectedDistributorId = "";
                                        selectedDistributorName = "";
                                        asmController.clear();
                                        rsmController.clear();
                                        customerController.clear();
                                        invoiceList = invoiceListTemp;
                                        sortInvoicesByDate();
                                        _findCollectionTarget();
                                        collectionCheckList = List<bool>.filled(
                                          invoiceList.length,
                                          true,
                                        );
                                        selectedInvoiceList = List.from(
                                          invoiceList,
                                        );
                                        getCustomer("");
                                        getASM("");
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                        onSelected: (InvoiceCustomers value) {
                          customerController.text = value.customerName;
                          setState(() {
                            customerController.text = value.customerName;
                            selectedDistributorName = value.customerName;
                            invoiceList = invoiceList
                                .where(
                                  (invoice) =>
                                      invoice.customerName ==
                                      value.customerName,
                                )
                                .toList();
                            _findCollectionTarget();
                            collectionCheckList = List<bool>.filled(
                              invoiceList.length,
                              false,
                            );
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
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    physics: const ClampingScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          final InvoiceCustomers option =
                                              options.elementAt(index);
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
                                  onTapItem:
                                      (InvoiceCustomers distributor) async {
                                        setState(() {
                                          customerController.text =
                                              distributor.customerName;
                                          selectedDistributorId =
                                              distributor.customerCode;
                                          selectedDistributorName =
                                              distributor.customerName;
                                          invoiceList = invoiceList
                                              .where(
                                                (invoice) =>
                                                    invoice.customerName ==
                                                    distributor.customerName,
                                              )
                                              .toList();
                                          _findCollectionTarget();
                                          collectionCheckList =
                                              List<bool>.filled(
                                                invoiceList.length,
                                                true,
                                              );
                                        });
                                      },
                                  suggestionBuilder: (data) =>
                                      ListTile(title: Text(data.customerName)),
                                  asyncSuggestions: (searchValue) =>
                                      getCustomer(searchValue),
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
                                        setState(() {
                                          chartDataLoadedCustomerCollection =
                                              false;
                                        });
                                        setState(() {
                                          selectedDistributorId = "";
                                          selectedDistributorName = "";
                                          asmController.clear();
                                          rsmController.clear();
                                          customerController.clear();
                                          invoiceList = invoiceListTemp;
                                          collectionCheckList =
                                              List<bool>.filled(
                                                invoiceList.length,
                                                true,
                                              );
                                          selectedInvoiceList = List.from(
                                            invoiceList,
                                          );
                                          sortInvoicesByDate();
                                          _findCollectionTarget();
                                          getCustomer("");
                                          getASM("");
                                        });
                                        setState(() {
                                          chartDataLoadedCustomerCollection =
                                              true;
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 16.0, left: 16.0),
                      child: Text(
                        "Pending Invoice-Collection Remark",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 4.0,
                    bottom: 4.0,
                  ),
                  child: Text(
                    "Sorted by Due Date (Oldest First)",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
                                defaultColumnWidth: const FixedColumnWidth(
                                  175.0,
                                ),
                                border: TableBorder.all(
                                  color: Colors.black,
                                  style: BorderStyle.solid,
                                  width: 0.5,
                                ),
                                children: [
                                  /// HEADER ROW (unchanged)
                                  TableRow(
                                    children: [
                                      Row(
                                        children: [
                                          Transform.scale(
                                            scale: .7,
                                            child: Checkbox(
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

                                      TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        child: Container(
                                          height: 50,
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'Customer Name',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        child: Container(
                                          height: 50,
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'Value',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        child: Container(
                                          height: 50,
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'Status',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        child: Container(
                                          height: 50,
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'Payment Issues',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        child: Container(
                                          height: 50,
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'Commitment',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        child: Container(
                                          height: 50,
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'Expected Payment Date',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        child: Container(
                                          height: 50,
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'Expected Payment Remarks',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  /// DATA ROWS (UPDATED PROPERLY)
                                  ...List.generate(invoiceList.length, (i) {
                                    final balance =
                                        double.tryParse(
                                          invoiceList[i].balance,
                                        )?.abs() ??
                                        0;

                                    final commitment =
                                        double.tryParse(
                                          invoiceList[i].commitment,
                                        ) ??
                                        0;

                                    final isPartial =
                                        commitment > 0 && commitment < balance;

                                    final isFull =
                                        commitment >= balance && balance > 0;

                                    return TableRow(
                                      decoration: BoxDecoration(
                                        color: isFull
                                            ? const Color(
                                                0xFFD4EDDA,
                                              ) // light green
                                            : isPartial
                                            ? const Color(
                                                0xFFFFF3CD,
                                              ) // light yellow
                                            : null,
                                      ),
                                      children: [
                                        /// Checkbox + Invoice
                                        Column(
                                          children: [
                                            Row(
                                              children: [
                                                Transform.scale(
                                                  scale: .7,
                                                  child: Checkbox(
                                                    value:
                                                        collectionCheckList[i],
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        collectionCheckList[i] =
                                                            value ?? false;

                                                        final balance =
                                                            double.parse(
                                                              invoiceList[i]
                                                                  .balance,
                                                            ).abs();

                                                        if (collectionCheckList[i]) {
                                                          totalValue += balance;
                                                          selectedInvoiceList
                                                              .add(
                                                                invoiceList[i],
                                                              );
                                                        } else {
                                                          totalValue -= balance;
                                                          selectedInvoiceList
                                                              .remove(
                                                                invoiceList[i],
                                                              );

                                                          // Reset commitment when unchecked
                                                          invoiceList[i]
                                                                  .commitment =
                                                              "0";
                                                        }

                                                        valueController
                                                            .text = totalValue
                                                            .toStringAsFixed(0);

                                                        // Recalculate distribution
                                                        applyCommitmentDistribution();
                                                      });
                                                    },
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    "${invoiceList[i].documentNumber}/\n${invoiceList[i].postingDate}",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        /// Customer
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            invoiceList[i].customerName,
                                          ),
                                        ),

                                        /// Value
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              balance.toStringAsFixed(2),
                                            ),
                                          ),
                                        ),

                                        /// Status
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(invoiceList[i].dueDays),
                                        ),

                                        /// Issues
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            invoiceList[i].invoiceIssues,
                                          ),
                                        ),

                                        /// Commitment (READ ONLY)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    commitment.toStringAsFixed(
                                                      2,
                                                    ),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),

                                                  /// Progress Bar
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

                                        /// Expected Payment
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            invoiceList[i].expectedPayment,
                                          ),
                                        ),

                                        /// Remarks
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            invoiceList[i]
                                                .expectedPaymentRemarks,
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 20),
                    Container(
                      color: const Color(0xFFD9D9D9),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          "Total Outstanding - ${formatAmount(totalOutstanding)}",
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0),
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
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 8.0,
                  ),
                  child: SizedBox(
                    height: 70,
                    width: 400,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: DropdownButtonFormField<String>(
                        hint: const Text(
                          'Invoice Issues',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8F8F8F),
                          ),
                        ),
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
                    child: AbsorbPointer(
                      absorbing: disableSave,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: disableSave
                              ? Colors.grey
                              : const Color(0xff2ca9df),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                        onPressed: () async {
                          await submitLeads();
                          setState(() {
                            disableSave = true;
                            showAlertDialog(context);
                            collectionCheckList = List<bool>.filled(
                              invoiceList.length,
                              false,
                            );
                          });
                        },
                        child: const SizedBox(
                          width: 400,
                          child: Center(
                            child: Text(
                              "Save",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
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
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
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
                                formatAmount(collectionAchieved),
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black,
                                ),
                              ),
                              const Center(
                                child: Text(
                                  "Collection Progress (%)",
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
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
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
                                            if (!event
                                                    .isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse
                                                        .touchedSection ==
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
                                  generateCustomerCollectionExcel(
                                    receivablesAgingList,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  generateCustomerCollectionPDF(
                                    receivablesAgingList,
                                  );
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

  showAlertDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () {
        loadDataFuture = loadData("");
        clearVariables();
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Invoices Updated!"),
      content: const Text("Selected Invoices have been updated"),
      actions: [okButton],
    );
    disableSave = false;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
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
