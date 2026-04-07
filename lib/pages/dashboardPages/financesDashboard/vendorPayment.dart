// ignore_for_file: file_names, use_build_context_synchronously, non_constant_identifier_names, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/leads.dart';
import '../../../api_helper.dart';
import '../../../classes/dashBoard.dart';
import '../../../login_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';
import 'package:optima/pages/dashboardPages/pdf_helper_web.dart';

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
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController paymentRemarksController =
      TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController commitmentController = TextEditingController();
  String? selectedModeOfPayment = "Payment Outstanding Invoice";
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
    List<InvoiceCustomers> filteredList = invoiceList
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
    collectionCheckList = List.generate(invoiceList.length, (index) => false);
    for (var i = 0; i < collectionCheckList.length; i++) {
      collectionAchieved += double.parse(invoiceList[i].balance).abs();
    }
    chartDataLoaded = true;
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
        agingGroupTotal: agingGroup1Total.abs(),
        agingPercentage: 0,
        agingTotal: totalDueAmount.abs(),
      ),
    );
    receivablesAgingDataList.add(
      ReceivablesAgingData(
        agingGroup: "31-60",
        agingGroupTotal: agingGroup2Total.abs(),
        agingPercentage: 0,
        agingTotal: totalDueAmount.abs(),
      ),
    );
    receivablesAgingDataList.add(
      ReceivablesAgingData(
        agingGroup: "61-90",
        agingGroupTotal: agingGroup3Total.abs(),
        agingPercentage: 0,
        agingTotal: totalDueAmount.abs(),
      ),
    );
    receivablesAgingDataList.add(
      ReceivablesAgingData(
        agingGroup: "90+",
        agingGroupTotal: agingGroup4Total.abs(),
        agingPercentage: 0,
        agingTotal: totalDueAmount.abs(),
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
            ((collectionAgingGoal.abs() / collectionAchieved.abs()) * 100)
                .toStringAsFixed(2),
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

  Future<void> _loadCollectionTarget(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<PayablesList> targetList = [];
    try {
      do {
        var body = {
          "FromDate": dateFilterFlag
              ? formatDate(fromDateFilter!)
              : formatDate(fiscalYearStartDate!),
          "ToDate": dateFilterFlag
              ? formatDate(toDateFilter!)
              : formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoCreditorsAgingList';
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
            List<PayablesList> newTargetList =
                (responseJson['responseData'] as List)
                    .map((item) => PayablesList.fromJson(item))
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
        context.read<VendorPaymentProvider>().updateTargetList(targetList);
        if (int.parse(UserLevel) == 5) {
          target = targetList;
        } else if (int.parse(UserLevel) == 4) {
          target = targetList;
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          target = targetList;
        } else {
          target = targetList;
        }
      });

      double sum = 0;
      var currentMonthTarget = target.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.dueon);
        return dueon.isAtMost(currentMonthToDate!);
      });
      for (var target in currentMonthTarget.toList()) {
        double balance = double.tryParse(target.balance) ?? 0;
        sum += balance;
      }

      collectionAchieved = sum;
      collectionAchievedStr = sum.toString();

      var tempList = target.where((test) {
        return test.documentType == "Invoice";
      });

      invoiceList = tempList.toList();

      invoiceListTemp = invoiceList;

      customers = invoiceList
          .map(
            (item) => InvoiceCustomers(
              customerName: item.vendorName,
              customerCode: item.vendorCode,
              salesManager: "",
              regionalManager: "",
            ),
          )
          .toList();
      customers = customers.toSet().toList();
      asmList = asmList.toSet().toList();
    } catch (e) {
      const snackBar = SnackBar(
        duration: Duration(seconds: 2),
        content: Text(''),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
        }
        //   else if (response.statusCode == 504) {
        //     await _loadModeOfPayment(UserName, UserLevel);
        //   } else if (response.statusCode == 502) {
        // await _loadModeOfPayment(UserName, UserLevel);
        // }
        else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        context.read<VendorPayableProvider>().updateTargetList(salesList);
        if (int.parse(UserLevel) == 5) {
          if (modeOfPayment.isEmpty) {
            modeOfPayment = salesList.toList();
          }
        } else if (int.parse(UserLevel) == 4) {
          if (modeOfPayment.isEmpty) {
            modeOfPayment = salesList.toList();
          }
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          if (modeOfPayment.isEmpty) {
            modeOfPayment = salesList.toList();
          }
        } else {
          if (modeOfPayment.isEmpty) {
            modeOfPayment = salesList.toList();
          }
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

  Future<void> submitLeads() async {
    String date = _dateController.text;

    selectedInvoices = selectedInvoiceList
        .whereType<PayablesList>()
        .map(
          (PayablesList item) => {
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
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        const snackBar = SnackBar(
          content: Text('Payment comments updation failed'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void clearVariables() {
    setState(() {
      _dateController.clear();
      remarksController.clear();
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

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> generateReceivablesExcel(ReceivablesAgingList list) async {
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
        saveAndOpenExcel('allReceivables.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/allReceivables.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateReceivablesPDF(ReceivablesAgingList list) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Receivables',
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
                for (var data in receivablesAgingList.agingData)
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
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        // Generate bytes
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/allReceivables.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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

      for (var i = 0; i < collectionCheckList.length; i++) {
        collectionCheckList[i] = selectAll;

        // 2) only add when selected
        if (selectAll) {
          total += double.parse(invoiceList[i].balance).abs();
        }
        selectedInvoiceList.add(invoiceList[i]);
      }

      if (selectAll) {
        valueController.text = total.toStringAsFixed(0);
      } else {
        valueController.text = '0';
      }
    });
  }

  Future<void> _loadVendorPaymentProjection() async {
    List<VendorsPaymentProjectionData> vendorWiseData = [];
    var customerTargetList = const Iterable.empty();
    var currentMonthActualPayable = const Iterable.empty();
    double balance = 0.0;
    double commitment = 0.0;
    var overDueDays = 0;
    double a0to30 = 0.0;
    double a31to60 = 0;
    double a61to90 = 0;
    double a90to180 = 0;
    double a180above = 0;
    String vendorCode = "";
    String vendorName = "";

    customerTargetList = target.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return dueon.isAtMost(currentMonthToDate!);
    });

    currentMonthActualPayable = modeOfPayment.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return dueon.isAtLeast(currentMonthFromDate!) &&
          dueon.isAtMost(currentMonthToDate!);
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
          commitment = double.tryParse(sales.commitment) ?? 0;
          overDueDays =
              int.tryParse(sales.dueDays.replaceAll(' Days', '')) ?? 0;
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
    vendorProjectionList = VendorsPaymentProjectionList(
      vendorData: vendorWiseData,
    );
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
      saveAndOpenExcel('monthlyCollectionReport.xlsx', excelBytes);

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
    chartDataLoaded = true;
  }

  void toggleCheckbox() {
    setState(() {
      chartDataLoaded = false;
      loadData("");
      // selectedCheckbox = index;
    });
  }

  // void _toggleSelectAll(bool? selectAll) {
  //   if (selectAll == null) return;
  //   setState(() {
  //     for (int i = 0; i < invoiceList.length; i++) {
  //       // if this invoice is in your filtered/search results...
  //       if (invoiceList.contains(invoiceListTemp[i])) {
  //         // … set its checkbox state
  //         if (i < collectionCheckList.length) {
  //           collectionCheckList[i] = selectAll;
  //           // or whatever
  //         } else {
  //           // log or ignore
  //           debugPrint('Skipped index $i because list length is ${collectionCheckList.length}');
  //         }
  //       }
  //     }
  //   });
  // }

  @override
  void initState() {
    _focusInvoice = FocusNode();
    // selectedModeOfPayment = null;
    loadDataFuture = loadData("");
    super.initState();
    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
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
    return chartDataLoaded == true
        ? SingleChildScrollView(
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
                                      setState(() {
                                        selectedDistributorId = "";
                                        selectedDistributorName = "";
                                        invoiceList = invoiceListTemp;
                                        collectionCheckList = List<bool>.filled(
                                          invoiceList.length,
                                          false,
                                        );
                                        customerController.clear();
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
                                      invoice.vendorName == value.customerName,
                                )
                                .toList();
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
                                                    invoice.vendorName ==
                                                    distributor.customerName,
                                              )
                                              .toList();
                                          collectionCheckList =
                                              List<bool>.filled(
                                                invoiceList.length,
                                                false,
                                              );
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
                                        setState(() {
                                          selectedDistributorId = "";
                                          selectedDistributorName = "";
                                          customerController.clear();
                                          invoiceList = invoiceListTemp;
                                          // collectionCheckList = List<bool>.filled(invoiceListTemp.length, false);
                                          collectionCheckList =
                                              List<bool>.filled(
                                                invoiceList.length,
                                                false,
                                              );
                                          // invoiceList = invoiceListTemp
                                          //     .where((invoice) =>
                                          // invoice.vendorName ==
                                          //     asmController.text)
                                          //     .toList();
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
                                    generateVendorPaymentProjectionReport();
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
                                defaultColumnWidth: const FixedColumnWidth(
                                  175.0,
                                ),
                                border: TableBorder.all(
                                  color: Colors.black,
                                  style: BorderStyle.solid,
                                  width: 0.5,
                                ),
                                children: [
                                  TableRow(
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
                                      const Column(
                                        children: [
                                          Text(
                                            'Vendor Name',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Column(
                                        children: [
                                          Text(
                                            'Value',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Column(
                                        children: [
                                          Text(
                                            'Status',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Column(
                                        children: [
                                          Text(
                                            'Payment Issues',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Column(
                                        children: [
                                          Text(
                                            'Commitment',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Column(
                                        children: [
                                          Text(
                                            'Payment Date',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Column(
                                        children: [
                                          Text(
                                            'Payment Remarks',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  for (var i = 0; i < invoiceList.length; i++)
                                    TableRow(
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
                                                          BorderRadius.circular(
                                                            2.0,
                                                          ),
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
                                                    value:
                                                        collectionCheckList[i],
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        collectionCheckList[i] =
                                                            value ?? false;
                                                        if (collectionCheckList[i] ==
                                                            true) {
                                                          totalValue +=
                                                              double.parse(
                                                                invoiceList[i]
                                                                    .balance,
                                                              ).abs();
                                                          valueController.text =
                                                              totalValue
                                                                  .toString();
                                                          selectedInvoiceList
                                                              .add(
                                                                invoiceList[i],
                                                              );
                                                        }
                                                        if (collectionCheckList[i] ==
                                                            false) {
                                                          if (totalValue != 0) {
                                                            totalValue -=
                                                                double.parse(
                                                                  invoiceList[i]
                                                                      .balance,
                                                                ).abs();
                                                            valueController
                                                                    .text =
                                                                totalValue
                                                                    .toString();
                                                            selectedInvoiceList
                                                                .remove(
                                                                  invoiceList[i],
                                                                );
                                                          }
                                                        }
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
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: Text(
                                              invoiceList[i].vendorName
                                                  .toString(),
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
                                              child: Text(
                                                double.parse(
                                                  invoiceList[i].balance,
                                                ).abs().toStringAsFixed(2),
                                              ),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: Text(invoiceList[i].dueDays),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: Text(
                                              invoiceList[i].invoiceIssues,
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 70.0,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                invoiceList[i].commitment != ""
                                                    ? double.parse(
                                                        invoiceList[i]
                                                            .commitment,
                                                      ).toStringAsFixed(2)
                                                    : invoiceList[i].commitment,
                                              ),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: Text(
                                              invoiceList[i].expectedPayment,
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: Text(
                                              invoiceList[i]
                                                  .expectedPaymentRemarks,
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
                          child: TextField(
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
                        await submitLeads();
                        showAlertDialog(context);
                        setState(() {
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
                                  generateReceivablesExcel(
                                    receivablesAgingList,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  generateReceivablesPDF(receivablesAgingList);
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

                                      toggleCheckbox();

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
                                      chartDataLoaded = false;
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        chartDataLoaded = false;
                                        loadDataFuture = removeFilter();
                                        Navigator.pop(context);
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
