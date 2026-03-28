// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, avoid_print, unused_local_variable
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/scheduler.dart';
import 'package:optima/leadstages/stageoneentry.dart';
import 'package:optima/pages/addUpateMeeting/addMeetingPage.dart';
import 'package:optima/pages/addUpateMeeting/distributorMeetingPage.dart';
import 'package:optima/pages/addUpateMeeting/hospitalMeetingPage.dart';
import 'package:optima/pages/addUpateMeeting/otherMeetingPage.dart';
import 'package:optima/pages/addToDoList/toDoListPage.dart';
import 'package:optima/pages/customerdatapage.dart';
import 'package:optima/pages/dashboardPages/customerDashboard/customerDashboardPage.dart';
// import 'package:optima/pages/schedulerPage/schedulerPage.dart';
import '../api_helper.dart';
import '../classes/dashBoard.dart';
import '../classes/leads.dart';
import '../login_screen.dart';
import 'soAndSalesChartPage.dart';

String? allParticipants;
List<String> listOfRSM = [];
List<String> listOfASM = [];
List<String> listOfTSM = [];
List<String> listOfString = [];
List<List<String>> filterOptions = [
  listOfRSM,
  listOfASM,
  listOfTSM,
  listOfString,
  [],
];
List<LeadActivity> leadActivity = [];
List<CheckinDetails> checkinDetails = [];
List<ScheduledLeadActivity> scheduledLeadActivity = [];
String userRoleCode = "";
int totalSOPunchedCount = 0;
double totalSOPunchedValue = 0;
int totalInvoiceCount = 0;
double totalInvoiceValue = 0;

int totalDailySOPunchedCount = 0;
double totalDailySOPunchedValue = 0;
int totalDailyInvoiceCount = 0;
double totalDailyInvoiceValue = 0;

List<SalesList> sales = [];
List<SalesList> dailySales = [];
List<SODetailsList> soDetailList = [];
List<SODetailsList> dailySoDetailList = [];

class LeadMasterHomePageProvider with ChangeNotifier {
  LeadMaster _leadMaster = LeadMaster(
    leadID: 0,
    customerPaymentTerms: 0,
    customerCreditLimit: 0,
    customerCode: '',
    customerMOV: 0,
    customerName: '',
    customerAddress: '',
    leadStageLevel: '',
    leadStage: 0,
    leadStartDate: '',
    leadAging: '',
    leadAssigneeName: '',
    leadHospitalCode: '',
    leadDistributorCode: '',
    leadAssigneeId: 0,
    leadDealValue: '',
    leadHospitalName: '',
    leadDistributorName: '',
    leadProductName: '',
    leadType: '',
    leadInputMaterials: '',
  );

  LeadMaster get leadMaster => _leadMaster;
  void updateLeadMaster(LeadMaster newLeadMaster) {
    _leadMaster = newLeadMaster;
    notifyListeners(); // Notify listeners to rebuild widgets
  }
}

class LeadContactHomePageProvider with ChangeNotifier {
  List<LeadContact> _leadContacts = [];
  List<LeadContact> get leadContacts => _leadContacts;
  void updateLeadContacts(List<LeadContact> newLeadContacts) {
    _leadContacts = newLeadContacts;
    notifyListeners();
  }
}

class LeadActivityHomePageProvider with ChangeNotifier {
  List<LeadActivity> _leadActivity = [];
  List<LeadActivity> get leadActivity => _leadActivity;
  void updateLeadActivity(List<LeadActivity> newLeadActivity) {
    _leadActivity = newLeadActivity;
    notifyListeners();
  }
}

class ScheduledLeadActivityHomePageProvider with ChangeNotifier {
  List<ScheduledLeadActivity> _scheduledLeadActivity = [];
  List<ScheduledLeadActivity> get scheduledLeadActivity =>
      _scheduledLeadActivity;
  void updateSheduledLeadActivity(
    List<ScheduledLeadActivity> newScheduledLeadActivity,
  ) {
    _scheduledLeadActivity = newScheduledLeadActivity;
    notifyListeners();
  }
}

class CheckinDetailsHomePageProvider with ChangeNotifier {
  List<CheckinDetails> _checkinDetails = [];
  List<CheckinDetails> get checkinDetails => _checkinDetails;
  void updateCheckinDetails(List<CheckinDetails> newCheckinDetails) {
    _checkinDetails = newCheckinDetails;
    notifyListeners();
  }
}

class SchedulerApprovalProviderForHome with ChangeNotifier {
  List<MonthlyScheduleHomePage> _monthlySchedule = [];
  List<MonthlyScheduleHomePage> get monthlySchedule => _monthlySchedule;
  void updateMonthlyScheduler(
    List<MonthlyScheduleHomePage> newMonthlySchedule,
  ) {
    _monthlySchedule = newMonthlySchedule;
    notifyListeners();
  }
}

class SchedulerApprovalProviderForHomePending with ChangeNotifier {
  List<MonthlySchedule> _monthlySchedule = [];
  List<MonthlySchedule> get monthlySchedule => _monthlySchedule;
  void updateMonthlyScheduler(List<MonthlySchedule> newMonthlySchedule) {
    _monthlySchedule = newMonthlySchedule;
    notifyListeners();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class ScheduleWithParticipants {
  final MonthlyScheduleHomePage base;
  final List<String> participants;
  ScheduleWithParticipants(this.base, this.participants);
}

class SalesOrderListHomePageProvider with ChangeNotifier {
  List<SODetailsList> _soList = [];
  List<SODetailsList> get soList => _soList;
  void updateSalesOrder(List<SODetailsList> newSalesOrderList) {
    _soList = newSalesOrderList;
    notifyListeners();
  }
}

class SumCount {
  double sum;
  int count;
  SumCount(this.sum, this.count);
}

class HomePageState extends State<HomePage> {
  late Future<void> loadDataFuture;
  List<bool> isRejected = [];
  List<String> reasons = [];
  List<MonthlyScheduleHomePage> tmpScheduleList = [];
  List<MonthlyScheduleHomePage> monthlyScheduleListApproved = [];
  List<MonthlySchedule> tmpScheduleListPending = [];
  List<MonthlySchedule> monthlyScheduleListNotifications = [];
  List<MonthlyScheduleHomePage> monthlyScheduleListDetails = [];
  List<Users> usersList = [];
  List<Users> childUsers = [];
  List<Map<String, dynamic>> userList = [];
  Map<String, Map<String, bool>> allCategoriesState = {};
  final List<String> categories = ['RSM', 'ASM', 'TSM', 'Status', 'Date'];
  String? selectedMonth;
  String? selectedDate;

  @override
  void initState() {
    super.initState();
    loadDataFuture = _initializeData();
  }

  String _formatValue(double value) {
    if (value >= 100000) {
      return "${(value / 100000).toStringAsFixed(2)} L";
    }
    return value.toStringAsFixed(0);
  }

  List<ScheduleWithParticipants> _groupSchedules(
    List<MonthlyScheduleHomePage> raw,
  ) {
    final Map<int, List<String>> byId = {};
    for (var item in raw) {
      if (item.scheduleType == 'Participant') {
        byId.putIfAbsent(item.scheduleID, () => []).add(item.participantName);
      }
    }

    final Map<int, MonthlyScheduleHomePage> baseById = {};
    for (var item in raw) {
      if (baseById.containsKey(item.scheduleID)) continue;
      if (item.scheduleType != 'Participant') {
        baseById[item.scheduleID] = item;
      }
    }

    return baseById.entries.map((e) {
      final pid = e.key;
      return ScheduleWithParticipants(e.value, byId[pid] ?? <String>[]);
    }).toList();
  }

  Future<void> _initializeData() async {
    isUserLoggedIn = await DataManager.readLoginStatus();
    if (isUserLoggedIn) {
      await loadData();
    }
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  String previousMonthLastDay(DateTime date) {
    final lastDayPrevMonth = DateTime(date.year, date.month, 0);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final y = lastDayPrevMonth.year;
    final m = twoDigits(lastDayPrevMonth.month);
    final d = twoDigits(lastDayPrevMonth.day);

    return '$y-$m-$d';
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
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
            navigateToLoginScreen();
          }
        }
      } else {
        const snackBar = SnackBar(content: Text('User list not found.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text('Error: $e'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  List<SalesList> _applyUserFilter(
    List<SalesList> list,
    String userName,
    String userLevel,
  ) {
    final int level = int.parse(userLevel);

    if (level == 5) return list;

    final menuNames =
        usersList
            .where((e) => e.parentMenuId == 0)
            .map((e) => e.menuName)
            .toList()
          ..insert(0, userName);

    return list.where((e) {
      if (level == 4 && e.regionalManager != userName) {
        return false;
      }

      if (level >= 2 && level <= 3 && !menuNames.contains(e.salesManager)) {
        return false;
      }

      if (level < 2 && e.salesRep != userName) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userName = prefs.getString('userName') ?? '';
    final userLevel = prefs.getString('userLevel') ?? '';
    userRoleCode = prefs.getString('userRoleCode') ?? '';
    String? filterDate = DateFormat(
      'dd/MM/yyyy',
    ).format(DataManager.readSelectedDate()!).toString();

    selectedDate = filterDate;
    selectedMonth = DateFormat('MMM yyyy')
        .format(
          DateTime(
            DateFormat('dd/MM/yyyy').parse(filterDate).year,
            DateFormat('dd/MM/yyyy').parse(filterDate).month,
            1,
          ),
        )
        .toString();

    if (userRoleCode == "R1" || userRoleCode == "R2") {
      await Future.wait([
        _loadUserList(
          userId,
          userJwtToken,
          userMailID,
          int.tryParse(userLevel) ?? 0,
        ),
        _selectCheckinDetails(userId, userJwtToken, userMailID, filterDate),
        _loadmonthlyscheduler(userId, userJwtToken, userMailID),
        _loadmonthlyschedulerfornotification(userId, userJwtToken, userMailID),
        _selectLeadsDetails(userId, userJwtToken, userMailID, filterDate),
        _selectLeadActivity(userId, userJwtToken, userMailID, filterDate),
        _selectScheduledLeadActivity(
          userId,
          userJwtToken,
          userMailID,
          filterDate,
        ),
        _loadSODetails(userName, userLevel, filterDate),
        _loadSalesDetails(
          userName: userName,
          userLevel: userLevel,
          filterDate: filterDate,
        ),
      ]);
    }
  }

  Future<void> _loadSODetails(
    String UserName,
    String UserLevel,
    String FilterDate,
  ) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    soDetailList.clear();
    dailySoDetailList.clear();
    DateTime? selectedMonthFromDate = DateTime(
      DateFormat('dd/MM/yyyy').parse(FilterDate).year,
      DateFormat('dd/MM/yyyy').parse(FilterDate).month,
      1,
    );
    final parsedDate = DateFormat('dd/MM/yyyy').parse(FilterDate);
    try {
      do {
        var body = {
          "FromDate": formatDate(selectedMonthFromDate),
          "ToDate": formatDate(parsedDate),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}CRM_SOList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final List list = json['responseData'] ?? [];

          final newSalesOrder = list
              .map((e) => SODetailsList.fromJson(e))
              .toList();

          soDetailList.addAll(newSalesOrder);
          fetchedCount = newSalesOrder.length;
          index++;
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      final userLevelInt = int.tryParse(UserLevel) ?? 0;

      setState(() {
        context.read<SalesOrderListHomePageProvider>().updateSalesOrder(
          soDetailList,
        );

        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();

        menuNames.insert(0, UserName);

        if (userLevelInt == 5) {
          soDetailList = soDetailList.toList();
        } else if (userLevelInt == 4) {
          soDetailList = soDetailList
              .where((e) => e.regionalManager == UserName)
              .toList();
        } else if (userLevelInt >= 2 && userLevelInt <= 3) {
          soDetailList = soDetailList
              .where((e) => menuNames.contains(e.salesManager))
              .toList();
        } else {
          soDetailList = soDetailList
              .where((e) => e.salesRep == UserName)
              .toList();
        }

        if (listOfString.isEmpty) {
          listOfString = List<String>.from(
            soDetailList.map((e) => e.soStatus).toSet(),
          );
        }
      });

      // FILTERING
      List<String> trueRSMOptions = (allCategoriesState['RSM'] ?? {}).entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      List<String> trueASMOptions = (allCategoriesState['ASM'] ?? {}).entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      List<String> trueTSMOptions = (allCategoriesState['TSM'] ?? {}).entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      List<String> trueStatusOptions = (allCategoriesState['Status'] ?? {})
          .entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      soDetailList = soDetailList.where((person) {
        return (trueRSMOptions.isEmpty ||
                trueRSMOptions.contains(person.regionalManager)) &&
            (trueASMOptions.isEmpty ||
                trueASMOptions.contains(person.salesManager)) &&
            (trueTSMOptions.isEmpty ||
                trueTSMOptions.contains(person.salesRep)) &&
            (trueStatusOptions.isEmpty ||
                trueStatusOptions.contains(person.soStatus));
      }).toList();

      final Map<String, List<String>> soNosMap = {};
      final totalValue = soDetailList.fold<double>(0, (sum, item) {
        soNosMap.putIfAbsent(item.customerCode, () => []);
        soNosMap[item.customerCode]!.add(item.soNo);
        return sum + (double.tryParse(item.orderValue) ?? 0);
      });
      var result = SumCount(totalValue, soNosMap.length);

      setState(() {
        totalSOPunchedValue = result.sum;
        totalSOPunchedCount = result.count;

        dailySoDetailList = soDetailList.where((target) {
          DateTime invDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
          return (invDate.isAtLeast(parsedDate) &&
              invDate.isAtMost(parsedDate));
        }).toList();

        final Map<String, List<String>> soNosMap = {};
        final totalValue = dailySoDetailList.fold<double>(0, (sum, item) {
          soNosMap.putIfAbsent(item.customerCode, () => []);
          soNosMap[item.customerCode]!.add(item.soNo);
          return sum + (double.tryParse(item.orderValue) ?? 0);
        });
        result = SumCount(totalValue, soNosMap.length);
        totalDailySOPunchedValue = result.sum;
        totalDailySOPunchedCount = result.count;
      });
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadSalesDetails({
    required String userName,
    required String userLevel,
    required String filterDate,
  }) async {
    const int limit = 5000;
    int index = 0;
    bool hasMore = true;
    sales.clear();
    dailySales.clear();
    DateTime? selectedMonthFromDate = DateTime(
      DateFormat('dd/MM/yyyy').parse(filterDate).year,
      DateFormat('dd/MM/yyyy').parse(filterDate).month,
      1,
    );
    while (hasMore) {
      try {
        final parsedDate = DateFormat('dd/MM/yyyy').parse(filterDate);
        var body = {
          "FromDate": formatDate(selectedMonthFromDate),
          "ToDate": formatDate(parsedDate),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        final response = await http.post(
          Uri.parse('${ApiHelper.baseUrl}Crm_SalesList'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.acceptEncodingHeader: 'gzip',
          },
          body: jsonEncode(body),
        );
        if (response.statusCode != 200) break;
        final json = jsonDecode(response.body);
        final List list = json['responseData'] ?? [];
        if (list.isEmpty) {
          hasMore = false;
          final Map<String, List<String>> invoiceNosMap = {};
          final totalValue = sales.fold<double>(0, (sum, item) {
            invoiceNosMap.putIfAbsent(item.customerCode, () => []);
            invoiceNosMap[item.customerCode]!.add(item.invoiceNo);
            return sum + (double.tryParse(item.rowTotal) ?? 0);
          });
          var result = SumCount(totalValue, invoiceNosMap.length);

          setState(() {
            totalInvoiceValue = result.sum;
            totalInvoiceCount = result.count;

            dailySales = sales.where((target) {
              DateTime invDate = target.invoiceDate;
              return (invDate.isAtLeast(parsedDate) &&
                  invDate.isAtMost(parsedDate));
            }).toList();

            final Map<String, List<String>> invoiceNosMap = {};
            final totalValue = dailySales.fold<double>(0, (sum, item) {
              invoiceNosMap.putIfAbsent(item.customerCode, () => []);
              invoiceNosMap[item.customerCode]!.add(item.invoiceNo);
              return sum + (double.tryParse(item.rowTotal) ?? 0);
            });
            result = SumCount(totalValue, invoiceNosMap.length);
            totalDailyInvoiceValue = result.sum;
            totalDailyInvoiceCount = result.count;
          });
          break;
        }
        final newSales = list.map((e) => SalesList.fromJson(e)).toList();
        setState(() {
          sales.addAll(_applyUserFilter(newSales, userName, userLevel));
        });

        index++;
        // Small delay avoids network congestion
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        print('Background load error: $e');
        break;
      }
    }
  }

  Future<void> _selectLeadsDetails(
    String userId,
    String userJwtToken,
    String userMailID,
    String filterDate,
  ) async {
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadId': "0",
      'LeadDate': filterDate,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectleadsdetails';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = json.decode(response.body);
        if (responseJson['Status'] == true &&
            responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            var masDataArray = data[0];
            if (masDataArray is List && masDataArray.isNotEmpty) {
              var masData = masDataArray[0];
              if (masData is Map) {
                setState(() {
                  context.read<LeadMasterHomePageProvider>().updateLeadMaster(
                    LeadMaster.fromJson(masData as Map<String, dynamic>),
                  );
                });
              }
            } else {
              const snackBar = SnackBar(
                content: Text('Lead master not found.'),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
            if (data.length > 1 && data[1] is List) {
              List<LeadContact> newLeadContacts = (data[1] as List)
                  .map((item) => LeadContact.fromJson(item))
                  .toList();
              setState(() {
                context.read<LeadContactHomePageProvider>().updateLeadContacts(
                  newLeadContacts,
                );
              });
            } else {
              const snackBar = SnackBar(
                content: Text('Lead contacts not found.'),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          } else {
            const snackBar = SnackBar(content: Text('Leads are not found.'));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
        const snackBar = SnackBar(content: Text('Leads data is not available'));
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

  Future<void> _selectLeadActivity(
    String userId,
    String userJwtToken,
    String userMailID,
    String filterDate,
  ) async {
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LoadFullCustomerData': 1,
      'LeadId': "0",
      'LeadStage': 0,
      'LeadDate': filterDate,
      'ShowScheduledOnly': 0,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectleadsactivity';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = json.decode(response.body);
        if (responseJson['Status'] == true &&
            responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            if (data[0] is List) {
              List<LeadActivity> newLeadActivity = (data[0] as List)
                  .map((item) => LeadActivity.fromJson(item))
                  .toList();
              setState(() {
                context.read<LeadActivityHomePageProvider>().updateLeadActivity(
                  newLeadActivity,
                );
                leadActivity = newLeadActivity;
              });
            }
          } else {
            const snackBar = SnackBar(
              content: Text('Leads activity details not found.'),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
          content: Text('Leads activity details not found.'),
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

  Future<void> _selectScheduledLeadActivity(
    String userId,
    String userJwtToken,
    String userMailID,
    String filterDate,
  ) async {
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LoadFullCustomerData': 1,
      'LeadId': "0",
      'LeadStage': 0,
      'LeadDate': filterDate,
      'ShowScheduledOnly': 1,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectleadsactivity';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = json.decode(response.body);
        if (responseJson['Status'] == true &&
            responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            if (data[0] is List) {
              List<ScheduledLeadActivity> newScheduledLeadActivity =
                  (data[0] as List)
                      .map((item) => ScheduledLeadActivity.fromJson(item))
                      .toList();
              setState(() {
                context
                    .read<ScheduledLeadActivityHomePageProvider>()
                    .updateSheduledLeadActivity(newScheduledLeadActivity);
                scheduledLeadActivity = newScheduledLeadActivity;
              });
            }
          } else {
            const snackBar = SnackBar(
              content: Text('Scheduled Leads activity details not found.'),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
          content: Text('Scheduled Leads activity details not found.'),
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

  Future<void> _selectCheckinDetails(
    String userId,
    String userJwtToken,
    String userMailID,
    String filterDate,
  ) async {
    List<CheckinDetails> newList = [];
    setState(() {
      newList = [];
      context.read<CheckinDetailsHomePageProvider>().updateCheckinDetails(
        newList,
      );
      checkinDetails = newList;
    });
    final data = {
      'UserId': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'CheckinId': "0",
    };

    const apiUrl = '${ApiHelper.baseUrl}selectcheckindetails';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = json.decode(response.body);
        if (responseJson['Status'] == true &&
            responseJson["Data"].toString().isNotEmpty) {
          List<CheckinDetails> newChechDetailsList =
              (responseJson['Data'] as List)
                  .map((item) => CheckinDetails.fromJson(item))
                  .toList();
          newList.addAll(newChechDetailsList);

          setState(() {
            context.read<CheckinDetailsHomePageProvider>().updateCheckinDetails(
              newList,
            );
            checkinDetails = newList;
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
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        const snackBar = SnackBar(content: Text('Checkin details not found.'));
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

  Future<void> _loadmonthlyscheduler(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    String? filterDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DataManager.readSelectedDate()!).toString();

    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'GivenDate': filterDate,
      'ScheduleStatus': 'A',
    };
    const apiUrl = '${ApiHelper.baseUrl}loadmonthlyschedulerapproved';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      monthlyScheduleListApproved = [];
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);

        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            List<MonthlyScheduleHomePage> newMonthlySchedule = data
                .map((item) => MonthlyScheduleHomePage.fromJson(item))
                .toList();
            if (mounted) {
              setState(() {
                context
                    .read<SchedulerApprovalProviderForHome>()
                    .updateMonthlyScheduler(newMonthlySchedule);
                monthlyScheduleListApproved = newMonthlySchedule;
                tmpScheduleList = monthlyScheduleListApproved;
              });
            }
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
          content: Text('Monthly schedules are not available.'),
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

  Future<void> _loadmonthlyschedulerfornotification(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    String? filterDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DataManager.readSelectedDate()!).toString();

    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
    };
    const apiUrl = '${ApiHelper.baseUrl}loadmonthlyschedulerfornotification';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      monthlyScheduleListNotifications = [];
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            List<MonthlySchedule> newMonthlySchedule = data
                .map((item) => MonthlySchedule.fromJson(item))
                .toList();
            if (mounted) {
              setState(() {
                context
                    .read<SchedulerApprovalProviderForHomePending>()
                    .updateMonthlyScheduler(newMonthlySchedule);
                monthlyScheduleListNotifications = newMonthlySchedule;
                tmpScheduleListPending = monthlyScheduleListNotifications;
                isRejected = List.filled(
                  monthlyScheduleListNotifications.length,
                  false,
                );
                reasons = List.filled(
                  monthlyScheduleListNotifications.length,
                  '',
                );
              });
            }
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
          content: Text('Monthly schedules are not available.'),
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

  Future<void> _updatemonthlyschedulestatus(
    int scheduleId,
    String scheduleStatus,
    String scheduleRemarks,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userName = prefs.getString('userName') ?? '';

    if (scheduleStatus == 'R') {
      setState(() {
        scheduleRemarks = 'Request rejected by $userName $scheduleRemarks';
      });
    }

    final payload = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'ScheduleId': scheduleId,
      'ScheduleStatus': scheduleStatus,
      'ScheduleRemarks': scheduleRemarks,
    };
    const apiUrl = '${ApiHelper.baseUrl}updatemonthlyschedulestatus';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(payload),
        headers: headerss,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Updated Successfully")));
        await _loadmonthlyschedulerfornotification(
          userId,
          userJwtToken,
          userMailID,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<void>(
          future: loadDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return customerData();
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    leadActivity = [];
    scheduledLeadActivity = [];
    checkinDetails = [];
    super.dispose();
  }

  ScrollController scrollControllerMain = ScrollController();
  ScrollController scrollControllerLead = ScrollController();
  ScrollController scrollControllerActivity = ScrollController();

  final TextEditingController _reasonController = TextEditingController();

  Widget customerData() {
    LeadActivityHomePageProvider leadActivityProvider = context
        .watch<LeadActivityHomePageProvider>();
    leadActivity = leadActivityProvider.leadActivity;

    ScheduledLeadActivityHomePageProvider scheduledLeadActivityProvider =
        context.watch<ScheduledLeadActivityHomePageProvider>();
    scheduledLeadActivity = scheduledLeadActivityProvider.scheduledLeadActivity;

    CheckinDetailsHomePageProvider checkinDetailsProvider = context
        .watch<CheckinDetailsHomePageProvider>();
    checkinDetails = checkinDetailsProvider.checkinDetails;

    LeadContactHomePageProvider leadContactProvider = context
        .watch<LeadContactHomePageProvider>();
    List<LeadContact> leadContacts = leadContactProvider.leadContacts;
    final grouped = _groupSchedules(monthlyScheduleListApproved);

    return Align(
      alignment: Alignment.topLeft,
      child: RawScrollbar(
        thumbColor: Colors.grey,
        radius: const Radius.circular(8),
        thickness: 7,
        controller: scrollControllerMain,
        child: RefreshIndicator(
          onRefresh: () => _refresh(),
          child: SingleChildScrollView(
            controller: scrollControllerMain,
            physics: const ScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Visibility(
                  visible: userRoleCode == "R1" || userRoleCode == "R2",
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 18, right: 18),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              "Activity",
                              style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff2ca9df),
                                height: 11 / 14,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_rounded,
                                size: 24,
                                color: Color(0xff2ca9df),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MeetingHomePage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          0,
                          20,
                          0,
                        ),
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Checkout Pending",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff2ca9df),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 4,
                                    color: Color(0x34090F13),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(0),
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  0,
                                  0,
                                  0,
                                  0,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: checkinDetails.isNotEmpty
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            for (var item in checkinDetails)
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          item.checkinCustomerType ==
                                                              "H"
                                                          ? HospitalMeetingPage(
                                                              checkInDetails:
                                                                  item,
                                                              fromHomePage:
                                                                  true,
                                                            )
                                                          : item.checkinCustomerType ==
                                                                "D"
                                                          ? DistributorMeetingPage(
                                                              fromHomePage:
                                                                  true,
                                                              checkInDetails:
                                                                  item,
                                                            )
                                                          : OtherMeetingPage(
                                                              fromHomePage:
                                                                  true,
                                                              checkInDetails:
                                                                  item,
                                                            ),
                                                    ),
                                                  );
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    8.0,
                                                  ),
                                                  child: Container(
                                                    width: 150,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                              item.checkinCustomerType ==
                                                                      "O"
                                                                  ? item.checkinPlaceOfVisit
                                                                  : item.checkinCustomerName,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 2,
                                                            ),
                                                          ),
                                                          Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                              item.checkinDisplayTime,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                      : const Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SizedBox(width: 50),
                                              Text(
                                                "No Pending Check In Details to Show",
                                                style: TextStyle(
                                                  fontFamily: "Roboto",
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          10,
                          20,
                          0,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Todays Plan",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff2ca9df),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_rounded,
                                    size: 24,
                                    color: Color(0xff2ca9df),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MeetingHomePage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              height: 130,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 4,
                                    color: Color(0x34090F13),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(0),
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  15,
                                  18,
                                  15,
                                  8,
                                ),
                                child: SingleChildScrollView(
                                  controller: scrollControllerActivity,
                                  child:
                                      scheduledLeadActivity
                                          .where(
                                            (element) =>
                                                element.leadType == "A",
                                          )
                                          .isNotEmpty
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            for (var item
                                                in scheduledLeadActivity.where(
                                                  (element) =>
                                                      element.leadType == "A",
                                                ))
                                              Column(
                                                children: [
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: ConstrainedBox(
                                                          constraints:
                                                              BoxConstraints(
                                                                maxWidth:
                                                                    MediaQuery.of(
                                                                      context,
                                                                    ).size.width -
                                                                    60,
                                                              ),
                                                          child: Text(
                                                            item.leadCustomerName ==
                                                                    ""
                                                                ? item.leadActivitySummary
                                                                : item.leadCustomerName,
                                                            maxLines: 3,
                                                            style:
                                                                const TextStyle(
                                                                  fontFamily:
                                                                      "Roboto",
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  color: Color(
                                                                    0xff454545,
                                                                  ),
                                                                  height: 0.99,
                                                                ),
                                                            softWrap: true,
                                                            overflow:
                                                                TextOverflow
                                                                    .clip,
                                                            textAlign:
                                                                TextAlign.left,
                                                          ),
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons.circle_outlined,
                                                        size: 10,
                                                        color: Color(
                                                          0xffe92729,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        item.leadPriority,
                                                        style: const TextStyle(
                                                          fontFamily: "Roboto",
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w300,
                                                          color: Color(
                                                            0xff454545,
                                                          ),
                                                          height: 14 / 9,
                                                        ),
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        size: 24,
                                                        color: Color(
                                                          0xff6ccc3f,
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible:
                                                            item.leadCategory !=
                                                            "O",
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            isCustomerDashboardStart =
                                                                true;
                                                            Navigator.of(
                                                              context,
                                                            ).push(
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    CustomerDashboardPage(
                                                                      initialPage:
                                                                          1,
                                                                      customerCode:
                                                                          item.leadCustomerCode,
                                                                    ),
                                                              ),
                                                            );
                                                          },
                                                          child: const Icon(
                                                            Icons
                                                                .pie_chart_outline,
                                                            size: 20,
                                                            color: Color(
                                                              0xff2CA9DF,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  Row(
                                                    children: [
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              top: 2.0,
                                                              right: 6,
                                                            ),
                                                        child: Icon(
                                                          Icons.people_outline,
                                                          size: 18,
                                                          color: Color(
                                                            0xff454545,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              item.leadParticipantUserName
                                                                  .split(",")
                                                                  .first
                                                                  .toString(),
                                                              style: const TextStyle(
                                                                fontFamily:
                                                                    "Roboto",
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w300,
                                                                color: Color(
                                                                  0xff454545,
                                                                ),
                                                                height: 14 / 9,
                                                              ),
                                                              maxLines: 3,
                                                              softWrap: true,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                              width: 5,
                                                            ),
                                                            Visibility(
                                                              visible:
                                                                  item.leadParticipantUserName
                                                                          .split(
                                                                            ",",
                                                                          )
                                                                          .length -
                                                                      1 !=
                                                                  0,
                                                              child: GestureDetector(
                                                                onTap: () {
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (
                                                                          BuildContext
                                                                          context,
                                                                        ) {
                                                                          return ShowAllParticipants(
                                                                            participants:
                                                                                item.leadParticipantUserName,
                                                                          );
                                                                        },
                                                                  );
                                                                },
                                                                child: Text(
                                                                  "+${(item.leadParticipantUserName.split(",").length - 1).toString()}",
                                                                  style: const TextStyle(
                                                                    fontFamily:
                                                                        "Roboto",
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color: Color(
                                                                      0xff454545,
                                                                    ),
                                                                    height:
                                                                        14 / 9,
                                                                  ),
                                                                  maxLines: 3,
                                                                  softWrap:
                                                                      true,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      for (var item
                                                          in item
                                                              .leadParticipantUserName
                                                              .split(","))
                                                        buildStack(),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Visibility(
                                                              visible:
                                                                  item.leadCategory ==
                                                                  "H",
                                                              child: const Padding(
                                                                padding:
                                                                    EdgeInsets.only(
                                                                      right:
                                                                          6.0,
                                                                    ),
                                                                child: Icon(
                                                                  Icons
                                                                      .people_outline,
                                                                  size: 18,
                                                                  color: Color(
                                                                    0xff454545,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            if (leadContacts.any(
                                                              (element) =>
                                                                  element
                                                                      .leadContactMasterId ==
                                                                  item.leadActivityMasterId,
                                                            ))
                                                              Text(
                                                                leadContacts
                                                                    .where(
                                                                      (
                                                                        element,
                                                                      ) =>
                                                                          element
                                                                              .leadContactMasterId ==
                                                                          item.leadActivityMasterId,
                                                                    )
                                                                    .first
                                                                    .leadContactName,
                                                                style: const TextStyle(
                                                                  fontFamily:
                                                                      "Roboto",
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300,
                                                                  color: Color(
                                                                    0xff454545,
                                                                  ),
                                                                  height:
                                                                      14 / 9,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                              ),
                                                            Visibility(
                                                              visible:
                                                                  leadContacts
                                                                          .where(
                                                                            (
                                                                              element,
                                                                            ) =>
                                                                                element.leadContactMasterId ==
                                                                                item.leadActivityMasterId,
                                                                          )
                                                                          .length -
                                                                      1 !=
                                                                  0,
                                                              child: Visibility(
                                                                visible:
                                                                    item.leadCategory ==
                                                                    "H",
                                                                child: GestureDetector(
                                                                  onTap: () {
                                                                    String
                                                                    parts = "";
                                                                    String
                                                                    parts2;
                                                                    leadContacts
                                                                        .where(
                                                                          (
                                                                            element,
                                                                          ) =>
                                                                              element.leadContactMasterId ==
                                                                              item.leadActivityMasterId,
                                                                        )
                                                                        .forEach((
                                                                          element,
                                                                        ) {
                                                                          parts2 =
                                                                              element.leadContactName;
                                                                          parts =
                                                                              "$parts2,$parts";
                                                                        });
                                                                    showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (
                                                                            BuildContext
                                                                            context,
                                                                          ) {
                                                                            return ShowAllParticipants(
                                                                              participants: parts,
                                                                            );
                                                                          },
                                                                    );
                                                                  },
                                                                  child: Text(
                                                                    ' +${leadContacts.where((element) => element.leadContactMasterId == item.leadActivityMasterId).length - 1}',
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w300,
                                                                      color: Color(
                                                                        0xff454545,
                                                                      ),
                                                                      height:
                                                                          14 /
                                                                          9,
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .left,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      for (var item
                                                          in leadContacts.where(
                                                            (element) =>
                                                                element
                                                                    .leadContactMasterId ==
                                                                item.leadActivityMasterId,
                                                          ))
                                                        buildStack(),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Activity Type - ${item.leadActivityType}",
                                                        style: const TextStyle(
                                                          fontFamily: "Roboto",
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Color(
                                                            0xff2ca9df,
                                                          ),
                                                          height: 14 / 9,
                                                        ),
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        "Time ${item.leadActivityTime}",
                                                        style: const TextStyle(
                                                          fontFamily: "Roboto",
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Color(
                                                            0xff2ca9df,
                                                          ),
                                                        ),
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  const Divider(
                                                    color: Colors.grey,
                                                    thickness: 1.0,
                                                    height: 20,
                                                  ),
                                                ],
                                              ),
                                          ],
                                        )
                                      : const Center(
                                          child: Text(
                                            "No Follow up to Show",
                                            style: TextStyle(
                                              fontFamily: "Roboto",
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          10,
                          20,
                          0,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 5),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Todays Activity - Completed",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff2ca9df),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              height: 230,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 4,
                                    color: Color(0x34090F13),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(0),
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  15,
                                  18,
                                  15,
                                  8,
                                ),
                                child: SingleChildScrollView(
                                  controller: scrollControllerActivity,
                                  child:
                                      leadActivity
                                          .where(
                                            (element) =>
                                                element.leadType == "A",
                                          )
                                          .isNotEmpty
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            for (var item in leadActivity.where(
                                              (element) =>
                                                  element.leadType == "A",
                                            ))
                                              Column(
                                                children: [
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: ConstrainedBox(
                                                          constraints:
                                                              BoxConstraints(
                                                                maxWidth:
                                                                    MediaQuery.of(
                                                                      context,
                                                                    ).size.width -
                                                                    60,
                                                              ),
                                                          child: Text(
                                                            item.leadCustomerName ==
                                                                    ""
                                                                ? item.leadActivitySummary
                                                                : item.leadCustomerName,
                                                            maxLines: 3,
                                                            style:
                                                                const TextStyle(
                                                                  fontFamily:
                                                                      "Roboto",
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  color: Color(
                                                                    0xff454545,
                                                                  ),
                                                                  height: 0.99,
                                                                ),
                                                            softWrap: true,
                                                            overflow:
                                                                TextOverflow
                                                                    .clip,
                                                            textAlign:
                                                                TextAlign.left,
                                                          ),
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons.circle_outlined,
                                                        size: 10,
                                                        color: Color(
                                                          0xffe92729,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        item.leadPriority,
                                                        style: const TextStyle(
                                                          fontFamily: "Roboto",
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w300,
                                                          color: Color(
                                                            0xff454545,
                                                          ),
                                                          height: 14 / 9,
                                                        ),
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        size: 24,
                                                        color: Color(
                                                          0xff6ccc3f,
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible:
                                                            item.leadCategory !=
                                                            "O",
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            isCustomerDashboardStart =
                                                                true;
                                                            Navigator.of(
                                                              context,
                                                            ).push(
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    CustomerDashboardPage(
                                                                      initialPage:
                                                                          1,
                                                                      customerCode:
                                                                          item.leadCustomerCode,
                                                                    ),
                                                              ),
                                                            );
                                                          },
                                                          child: const Icon(
                                                            Icons
                                                                .pie_chart_outline,
                                                            size: 20,
                                                            color: Color(
                                                              0xff2CA9DF,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  Row(
                                                    children: [
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              top: 2.0,
                                                              right: 6,
                                                            ),
                                                        child: Icon(
                                                          Icons.people_outline,
                                                          size: 18,
                                                          color: Color(
                                                            0xff454545,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              item.leadParticipantUserName
                                                                  .split(",")
                                                                  .first
                                                                  .toString(),
                                                              style: const TextStyle(
                                                                fontFamily:
                                                                    "Roboto",
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w300,
                                                                color: Color(
                                                                  0xff454545,
                                                                ),
                                                                height: 14 / 9,
                                                              ),
                                                              maxLines: 3,
                                                              softWrap: true,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                              width: 5,
                                                            ),
                                                            Visibility(
                                                              visible:
                                                                  item.leadParticipantUserName
                                                                          .split(
                                                                            ",",
                                                                          )
                                                                          .length -
                                                                      1 !=
                                                                  0,
                                                              child: GestureDetector(
                                                                onTap: () {
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (
                                                                          BuildContext
                                                                          context,
                                                                        ) {
                                                                          return ShowAllParticipants(
                                                                            participants:
                                                                                item.leadParticipantUserName,
                                                                          );
                                                                        },
                                                                  );
                                                                },
                                                                child: Text(
                                                                  "+${(item.leadParticipantUserName.split(",").length - 1).toString()}",
                                                                  style: const TextStyle(
                                                                    fontFamily:
                                                                        "Roboto",
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color: Color(
                                                                      0xff454545,
                                                                    ),
                                                                    height:
                                                                        14 / 9,
                                                                  ),
                                                                  maxLines: 3,
                                                                  softWrap:
                                                                      true,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      for (var item
                                                          in item
                                                              .leadParticipantUserName
                                                              .split(","))
                                                        buildStack(),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Visibility(
                                                              visible:
                                                                  item.leadCategory ==
                                                                  "H",
                                                              child: const Padding(
                                                                padding:
                                                                    EdgeInsets.only(
                                                                      right:
                                                                          6.0,
                                                                    ),
                                                                child: Icon(
                                                                  Icons
                                                                      .people_outline,
                                                                  size: 18,
                                                                  color: Color(
                                                                    0xff454545,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            if (leadContacts.any(
                                                              (element) =>
                                                                  element
                                                                      .leadContactMasterId ==
                                                                  item.leadActivityMasterId,
                                                            ))
                                                              Text(
                                                                leadContacts
                                                                    .where(
                                                                      (
                                                                        element,
                                                                      ) =>
                                                                          element
                                                                              .leadContactMasterId ==
                                                                          item.leadActivityMasterId,
                                                                    )
                                                                    .first
                                                                    .leadContactName,
                                                                style: const TextStyle(
                                                                  fontFamily:
                                                                      "Roboto",
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300,
                                                                  color: Color(
                                                                    0xff454545,
                                                                  ),
                                                                  height:
                                                                      14 / 9,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                              ),
                                                            Visibility(
                                                              visible:
                                                                  leadContacts
                                                                          .where(
                                                                            (
                                                                              element,
                                                                            ) =>
                                                                                element.leadContactMasterId ==
                                                                                item.leadActivityMasterId,
                                                                          )
                                                                          .length -
                                                                      1 !=
                                                                  0,
                                                              child: Visibility(
                                                                visible:
                                                                    item.leadCategory ==
                                                                    "H",
                                                                child: GestureDetector(
                                                                  onTap: () {
                                                                    String
                                                                    parts = "";
                                                                    String
                                                                    parts2;
                                                                    leadContacts
                                                                        .where(
                                                                          (
                                                                            element,
                                                                          ) =>
                                                                              element.leadContactMasterId ==
                                                                              item.leadActivityMasterId,
                                                                        )
                                                                        .forEach((
                                                                          element,
                                                                        ) {
                                                                          parts2 =
                                                                              element.leadContactName;
                                                                          parts =
                                                                              "$parts2,$parts";
                                                                        });
                                                                    showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (
                                                                            BuildContext
                                                                            context,
                                                                          ) {
                                                                            return ShowAllParticipants(
                                                                              participants: parts,
                                                                            );
                                                                          },
                                                                    );
                                                                  },
                                                                  child: Text(
                                                                    ' +${leadContacts.where((element) => element.leadContactMasterId == item.leadActivityMasterId).length - 1}',
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w300,
                                                                      color: Color(
                                                                        0xff454545,
                                                                      ),
                                                                      height:
                                                                          14 /
                                                                          9,
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .left,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      for (var item
                                                          in leadContacts.where(
                                                            (element) =>
                                                                element
                                                                    .leadContactMasterId ==
                                                                item.leadActivityMasterId,
                                                          ))
                                                        buildStack(),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Activity Type - ${item.leadActivityType}",
                                                        style: const TextStyle(
                                                          fontFamily: "Roboto",
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Color(
                                                            0xff2ca9df,
                                                          ),
                                                          height: 14 / 9,
                                                        ),
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        "Time ${item.leadActivityTime}",
                                                        style: const TextStyle(
                                                          fontFamily: "Roboto",
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Color(
                                                            0xff2ca9df,
                                                          ),
                                                        ),
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  const Divider(
                                                    color: Colors.grey,
                                                    thickness: 1.0,
                                                    height: 20,
                                                  ),
                                                ],
                                              ),
                                          ],
                                        )
                                      : const Center(
                                          child: Text(
                                            "No Activity to Show",
                                            style: TextStyle(
                                              fontFamily: "Roboto",
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Visibility(
                  visible: userRoleCode == "R1" || userRoleCode == "R2",
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 18, right: 18),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              "Daily Sales Activity",
                              style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff2ca9df),
                                height: 11 / 14,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_red_eye_outlined,
                                size: 24,
                                color: Color(0xff2ca9df),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SOAndSalesChartPage(
                                      soList: soDetailList,
                                      salesList: sales,
                                      soDailyList: dailySoDetailList,
                                      salesDailyList: dailySales,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          0,
                          20,
                          0,
                        ),
                        child: Row(
                          children: [
                            // SO BOX
                            Expanded(
                              child: _buildSummaryBox(
                                title: selectedMonth!,
                                dailyTitle: "SO Summary\n$selectedDate",
                                value: totalSOPunchedValue,
                                count: totalSOPunchedCount,
                                dailyValue: totalDailySOPunchedValue,
                                dailyCount: totalDailySOPunchedCount,
                                color: Colors.blue,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // INVOICE BOX
                            Expanded(
                              child: _buildSummaryBox(
                                title: selectedMonth!,
                                dailyTitle: "Invoice Summary\n$selectedDate",
                                value: totalInvoiceValue,
                                count: totalInvoiceCount,
                                dailyValue: totalDailyInvoiceValue,
                                dailyCount: totalDailyInvoiceCount,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Visibility(
                  visible: userRoleCode == "R1" || userRoleCode == "R2",
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          0,
                          16,
                          4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              "Lead",
                              style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff2ca9df),
                                height: 11 / 14,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_rounded,
                                size: 24,
                                color: Color(0xff2ca9df),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StageOneLeadEntryPage(
                                          leadsId: '0',
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              20,
                              5,
                              20,
                              12,
                            ),
                            child: Container(
                              width: double.infinity,
                              height: 240,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 4,
                                    color: Color(0x34090F13),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(0),
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  4,
                                  0,
                                  4,
                                  8,
                                ),
                                child: SingleChildScrollView(
                                  controller: scrollControllerLead,
                                  child:
                                      leadActivity
                                          .where(
                                            (element) =>
                                                element.leadType == "L",
                                          )
                                          .isNotEmpty
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            for (var item in leadActivity.where(
                                              (element) =>
                                                  element.leadType == "L",
                                            ))
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 5,
                                                ),
                                                color: const Color(0xFFFFFFFF),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ListTile(
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      title: Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 10.0,
                                                              right: 10,
                                                              top: 10,
                                                            ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: ConstrainedBox(
                                                                    constraints: BoxConstraints(
                                                                      maxWidth:
                                                                          MediaQuery.of(
                                                                            context,
                                                                          ).size.width -
                                                                          60,
                                                                    ),
                                                                    child: Text(
                                                                      item.leadCustomerName,
                                                                      maxLines:
                                                                          3,
                                                                      style: const TextStyle(
                                                                        fontFamily:
                                                                            "Roboto",
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                        color: Color(
                                                                          0xff454545,
                                                                        ),
                                                                        height:
                                                                            0.99,
                                                                      ),
                                                                      softWrap:
                                                                          true,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .clip,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .left,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const Icon(
                                                                  Icons
                                                                      .circle_outlined,
                                                                  size: 10,
                                                                  color: Color(
                                                                    0xffe92729,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Text(
                                                                  item.leadPriority,
                                                                  style: const TextStyle(
                                                                    fontFamily:
                                                                        "Roboto",
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color: Color(
                                                                      0xff454545,
                                                                    ),
                                                                    height:
                                                                        14 / 9,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .left,
                                                                ),
                                                              ],
                                                            ),
                                                            const Row(
                                                              children: [
                                                                Spacer(),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Lead No : ${item.leadActivityMasterId}',
                                                                  style: const TextStyle(
                                                                    fontFamily:
                                                                        "Roboto",
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color: Color(
                                                                      0xff454545,
                                                                    ),
                                                                    height:
                                                                        14 / 9,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Text(
                                                                      'Stage : ${item.leadActivityStageLevel}',
                                                                      style: const TextStyle(
                                                                        fontFamily:
                                                                            "Roboto",
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w300,
                                                                        color: Color(
                                                                          0xff454545,
                                                                        ),
                                                                        height:
                                                                            14 /
                                                                            9,
                                                                      ),
                                                                    ),
                                                                    const Icon(
                                                                      Icons
                                                                          .check_circle_outline,
                                                                      size: 24,
                                                                      color: Color(
                                                                        0xff6ccc3f,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      const Padding(
                                                                        padding: EdgeInsets.only(
                                                                          top:
                                                                              2.0,
                                                                          right:
                                                                              6,
                                                                        ),
                                                                        child: Icon(
                                                                          Icons
                                                                              .people_outline,
                                                                          size:
                                                                              18,
                                                                          color: Color(
                                                                            0xff454545,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        item.leadParticipantUserName
                                                                            .split(
                                                                              ",",
                                                                            )
                                                                            .first
                                                                            .toString(),
                                                                        style: const TextStyle(
                                                                          fontFamily:
                                                                              "Roboto",
                                                                          fontSize:
                                                                              14,
                                                                          fontWeight:
                                                                              FontWeight.w300,
                                                                          color: Color(
                                                                            0xff454545,
                                                                          ),
                                                                          height:
                                                                              14 /
                                                                              9,
                                                                        ),
                                                                        maxLines:
                                                                            3,
                                                                        softWrap:
                                                                            true,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            5,
                                                                      ),
                                                                      Visibility(
                                                                        visible:
                                                                            item.leadParticipantUserName.split(",").length -
                                                                                1 !=
                                                                            0,
                                                                        child: GestureDetector(
                                                                          onTap: () {
                                                                            showDialog(
                                                                              context: context,
                                                                              builder:
                                                                                  (
                                                                                    BuildContext context,
                                                                                  ) {
                                                                                    return ShowAllParticipants(
                                                                                      participants: item.leadParticipantUserName,
                                                                                    );
                                                                                  },
                                                                            );
                                                                          },
                                                                          child: Text(
                                                                            "+${(item.leadParticipantUserName.split(",").length - 1).toString()}",
                                                                            style: const TextStyle(
                                                                              fontFamily: "Roboto",
                                                                              fontSize: 14,
                                                                              fontWeight: FontWeight.w300,
                                                                              color: Color(
                                                                                0xff454545,
                                                                              ),
                                                                              height:
                                                                                  14 /
                                                                                  9,
                                                                            ),
                                                                            maxLines:
                                                                                3,
                                                                            softWrap:
                                                                                true,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                for (var item
                                                                    in item
                                                                        .leadParticipantUserName
                                                                        .split(
                                                                          ",",
                                                                        ))
                                                                  buildStack(),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Row(
                                                                    children: [
                                                                      const Padding(
                                                                        padding: EdgeInsets.only(
                                                                          top:
                                                                              2.0,
                                                                          right:
                                                                              6,
                                                                        ),
                                                                        child: Icon(
                                                                          Icons
                                                                              .people_outline,
                                                                          size:
                                                                              18,
                                                                          color: Color(
                                                                            0xff454545,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Visibility(
                                                                        visible:
                                                                            item.leadCategory ==
                                                                            "H",
                                                                        child: const Padding(
                                                                          padding: EdgeInsets.only(
                                                                            right:
                                                                                8.0,
                                                                          ),
                                                                          child: Icon(
                                                                            Icons.people_outline,
                                                                            size:
                                                                                18,
                                                                            color: Color(
                                                                              0xff454545,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      if (leadContacts.any(
                                                                        (
                                                                          element,
                                                                        ) =>
                                                                            element.leadContactMasterId ==
                                                                            item.leadActivityMasterId,
                                                                      ))
                                                                        Text(
                                                                          leadContacts
                                                                              .where(
                                                                                (
                                                                                  element,
                                                                                ) =>
                                                                                    element.leadContactMasterId ==
                                                                                    item.leadActivityMasterId,
                                                                              )
                                                                              .first
                                                                              .leadContactName,
                                                                          style: const TextStyle(
                                                                            fontFamily:
                                                                                "Roboto",
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.w300,
                                                                            color: Color(
                                                                              0xff454545,
                                                                            ),
                                                                            height:
                                                                                14 /
                                                                                9,
                                                                          ),
                                                                          textAlign:
                                                                              TextAlign.left,
                                                                        ),
                                                                      Visibility(
                                                                        visible:
                                                                            leadContacts
                                                                                    .where(
                                                                                      (
                                                                                        element,
                                                                                      ) =>
                                                                                          element.leadContactMasterId ==
                                                                                          item.leadActivityMasterId,
                                                                                    )
                                                                                    .length -
                                                                                1 !=
                                                                            0,
                                                                        child: GestureDetector(
                                                                          onTap: () {
                                                                            String
                                                                            parts =
                                                                                "";
                                                                            String
                                                                            parts2;
                                                                            leadContacts
                                                                                .where(
                                                                                  (
                                                                                    element,
                                                                                  ) =>
                                                                                      element.leadContactMasterId ==
                                                                                      item.leadActivityMasterId,
                                                                                )
                                                                                .forEach((
                                                                                  element,
                                                                                ) {
                                                                                  parts2 = element.leadContactName;
                                                                                  parts = "$parts2,$parts";
                                                                                });
                                                                            showDialog(
                                                                              context: context,
                                                                              builder:
                                                                                  (
                                                                                    BuildContext context,
                                                                                  ) {
                                                                                    return ShowAllParticipants(
                                                                                      participants: parts,
                                                                                    );
                                                                                  },
                                                                            );
                                                                          },
                                                                          child: Text(
                                                                            ' +${leadContacts.where((element) => element.leadContactMasterId == item.leadActivityMasterId).length - 1}',
                                                                            style: const TextStyle(
                                                                              fontSize: 14,
                                                                              fontWeight: FontWeight.w300,
                                                                              color: Color(
                                                                                0xff454545,
                                                                              ),
                                                                              height:
                                                                                  14 /
                                                                                  9,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.left,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    for (var item in leadContacts.where(
                                                                      (
                                                                        element,
                                                                      ) =>
                                                                          element
                                                                              .leadContactMasterId ==
                                                                          item.leadActivityMasterId,
                                                                    ))
                                                                      buildStack(),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 10,
                                                            right: 10,
                                                            bottom: 10,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            "Lead Type - ${item.leadActivityType}",
                                                            style:
                                                                const TextStyle(
                                                                  fontFamily:
                                                                      "Roboto",
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Color(
                                                                    0xff2ca9df,
                                                                  ),
                                                                  height:
                                                                      14 / 9,
                                                                ),
                                                            textAlign:
                                                                TextAlign.left,
                                                          ),
                                                          const Spacer(),
                                                          Text(
                                                            "Time ${item.leadActivityTime}",
                                                            style:
                                                                const TextStyle(
                                                                  fontFamily:
                                                                      "Roboto",
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Color(
                                                                    0xff2ca9df,
                                                                  ),
                                                                ),
                                                            textAlign:
                                                                TextAlign.left,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    const Divider(
                                                      color: Color(0xff454545),
                                                      thickness: 0.5,
                                                      height: 5,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        )
                                      : const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              "No Leads to Show",
                                              style: TextStyle(
                                                fontFamily: "Roboto",
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: userRoleCode == "",
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          0,
                          16,
                          4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              "To-do List",
                              style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff2ca9df),
                                height: 11 / 14,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_rounded,
                                size: 24,
                                color: Color(0xff2ca9df),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ToDoListPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          5,
                          20,
                          12,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 4,
                                color: Color(0x34090F13),
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              4,
                              0,
                              4,
                              8,
                            ),
                            child: SingleChildScrollView(
                              controller: scrollControllerLead,
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    "No data to Show",
                                    style: TextStyle(fontFamily: "Roboto"),
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
                Visibility(
                  visible: userRoleCode == "R1" || userRoleCode == "R2",
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(20, 0, 16, 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Reminders/Scheduler - Approved",
                              style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff2ca9df),
                                height: 11 / 14,
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          5,
                          20,
                          12,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 4,
                                color: Color(0x34090F13),
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: SingleChildScrollView(
                            controller: scrollControllerLead,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: monthlyScheduleListApproved.isNotEmpty
                                    ? SizedBox(
                                        height: 240,
                                        child: ListView.builder(
                                          physics:
                                              const ClampingScrollPhysics(),
                                          itemCount: grouped.length,
                                          itemBuilder: (context, idx) {
                                            final sched = grouped[idx].base;
                                            final parts =
                                                grouped[idx].participants;
                                            final day = sched.scheduleDate;
                                            final inputFormat = DateFormat(
                                              'yyyy/MM/dd',
                                            );
                                            final outputFormat = DateFormat(
                                              'dd/MM/yyyy',
                                            );

                                            DateTime dateTime = inputFormat
                                                .parse(day);

                                            String filterDate = outputFormat
                                                .format(dateTime);
                                            return Column(
                                              children: [
                                                SizedBox(
                                                  width: 375,
                                                  child: Container(
                                                    color: const Color(
                                                      0xFFefefef,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            // Date box
                                                            Column(
                                                              children: [
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        left:
                                                                            8.0,
                                                                        right:
                                                                            0,
                                                                      ),
                                                                  child: Text(
                                                                    filterDate,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Expanded(
                                                              child: ListTile(
                                                                title: Text(
                                                                  sched
                                                                      .scheduleCustomerName,
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                    color: Color(
                                                                      0xff454545,
                                                                    ),
                                                                    fontFamily:
                                                                        "Poppins",
                                                                  ),
                                                                ),
                                                                subtitle:
                                                                    parts
                                                                        .isEmpty
                                                                    ? null
                                                                    : Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: parts
                                                                            .map(
                                                                              (
                                                                                p,
                                                                              ) => Text(
                                                                                p,
                                                                                style: const TextStyle(
                                                                                  fontWeight: FontWeight.w300,
                                                                                  fontSize: 14,
                                                                                  color: Color(
                                                                                    0xff454545,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            )
                                                                            .toList(),
                                                                      ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                              ],
                                            );
                                          },
                                        ),
                                      )
                                    : const Text("No Data to show"),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: userRoleCode == "R1" || userRoleCode == "R2",
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(20, 0, 16, 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Monthly Schedule Participant\nRequests",
                              style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff2ca9df),
                                // height: 11 / 14,
                              ),
                            ),
                            Spacer(),
                            // IconButton(
                            //   icon: const Icon(
                            //     Icons.add_circle_rounded,
                            //     size: 24,
                            //     color: Color(0xff2ca9df),
                            //   ),
                            //   onPressed: () {
                            //     Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (context) => const SchedulerPage(),
                            //       ),
                            //     );
                            //   },
                            // ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          5,
                          20,
                          12,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 4,
                                color: Color(0x34090F13),
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: SingleChildScrollView(
                            // controller: scrollControllerLead,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child:
                                    monthlyScheduleListNotifications.isNotEmpty
                                    ? SizedBox(
                                        height: 240,
                                        child: ListView.builder(
                                          physics:
                                              const ClampingScrollPhysics(),
                                          itemCount:
                                              monthlyScheduleListNotifications
                                                  .length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final inputFormat = DateFormat(
                                              'yyyy/MM/dd',
                                            );
                                            final outputFormat = DateFormat(
                                              'dd/MM/yyyy',
                                            );

                                            DateTime
                                            dateTime = inputFormat.parse(
                                              monthlyScheduleListNotifications[index]
                                                  .scheduleDate,
                                            );

                                            String filterDate = outputFormat
                                                .format(dateTime);
                                            // final participants = monthlyScheduleList[index].participantList;
                                            return Column(
                                              children: <Widget>[
                                                Container(
                                                  color: const Color(
                                                    0xFFefefef,
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      SizedBox(
                                                        width: 375,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        left:
                                                                            8.0,
                                                                      ),
                                                                  child: Center(
                                                                    child: Text(
                                                                      filterDate
                                                                          .toString(),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        left:
                                                                            8.0,
                                                                      ),
                                                                  child: Text(
                                                                    monthlyScheduleListNotifications[index]
                                                                        .scheduleCustomerName,
                                                                    style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14,
                                                                      color: Color(
                                                                        0xff454545,
                                                                      ),
                                                                      fontFamily:
                                                                          "Poppins",
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        left:
                                                                            8.0,
                                                                      ),
                                                                  child: Text(
                                                                    monthlyScheduleListNotifications[index]
                                                                        .scheduledUser,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w300,
                                                                      color: Color(
                                                                        0xff454545,
                                                                      ),
                                                                      fontFamily:
                                                                          "Poppins",
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        left:
                                                                            8.0,
                                                                      ),
                                                                  child: Text(
                                                                    monthlyScheduleListNotifications[index]
                                                                        .scheduleRemarks,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: Color(
                                                                        0xff454545,
                                                                      ),
                                                                      fontFamily:
                                                                          "Poppins",
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Expanded(
                                                              child: ListTile(
                                                                title: const Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [],
                                                                ),
                                                                subtitle:
                                                                    isRejected[index] &&
                                                                        reasons[index]
                                                                            .isNotEmpty
                                                                    ? Padding(
                                                                        padding: const EdgeInsets.only(
                                                                          top:
                                                                              4.0,
                                                                        ),
                                                                        child: Text(
                                                                          "Reason: ${reasons[index]}",
                                                                          style: const TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                            color:
                                                                                Colors.redAccent,
                                                                          ),
                                                                        ),
                                                                      )
                                                                    : null,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.white,
                                                              foregroundColor:
                                                                  Colors.green,
                                                              minimumSize:
                                                                  const Size(
                                                                    60,
                                                                    30,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                              ),
                                                              textStyle:
                                                                  const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                            ),
                                                            onPressed: () async {
                                                              await _updatemonthlyschedulestatus(
                                                                monthlyScheduleListNotifications[index]
                                                                    .scheduleID,
                                                                'A',
                                                                '',
                                                              );
                                                            },
                                                            child: const Text(
                                                              'Accept',
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.white,
                                                              foregroundColor:
                                                                  Colors.red,
                                                              minimumSize:
                                                                  const Size(
                                                                    60,
                                                                    30,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                              ),
                                                              textStyle:
                                                                  const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                            ),
                                                            onPressed: () {
                                                              _reasonController
                                                                  .clear();
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder: (context) => AlertDialog(
                                                                  title: const Text(
                                                                    'Please enter a reason',
                                                                  ),
                                                                  content: TextField(
                                                                    controller:
                                                                        _reasonController,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                          hintText:
                                                                              'Reason?',
                                                                        ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () async {
                                                                        setState(() {
                                                                          isRejected[index] =
                                                                              true;
                                                                          reasons[index] = _reasonController
                                                                              .text
                                                                              .trim();
                                                                        });
                                                                        await _updatemonthlyschedulestatus(
                                                                          monthlyScheduleListNotifications[index]
                                                                              .scheduleID,
                                                                          'R',
                                                                          reasons[index],
                                                                        );
                                                                        Navigator.of(
                                                                          context,
                                                                        ).pop();
                                                                      },
                                                                      child:
                                                                          const Text(
                                                                            'OK',
                                                                          ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () =>
                                                                          Navigator.of(
                                                                            context,
                                                                          ).pop(),
                                                                      child: const Text(
                                                                        'Cancel',
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                            child: const Text(
                                                              'Reject',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                              ],
                                            );
                                          },
                                        ),
                                      )
                                    : const Text("No Data to show"),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
        ),
        const Icon(Icons.person, size: 14, color: Colors.white),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
            child: const Icon(Icons.check, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBox({
    required String title,
    required String dailyTitle,
    required double value,
    required int count,
    required double dailyValue,
    required int dailyCount,
    required Color color,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Color(0x33000000),
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              dailyTitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Value
            Text(
              "₹ ${_formatValue(dailyValue)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Count
            Text(
              "Count: $dailyCount",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),

            Divider(
              thickness: 1.5,
              height: 16,
              color: const Color.fromARGB(
                255,
                248,
                246,
                246,
              ).withValues(alpha: 0.9),
            ),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Value
            Text(
              "₹ ${_formatValue(value)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Count
            Text(
              "Count: $count",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    loadDataFuture = _initializeData();
    setState(() {});
  }
}

class ShowAllParticipants extends StatelessWidget {
  final String participants;
  const ShowAllParticipants({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('All Participants'),
      content: SingleChildScrollView(
        child: ListBody(children: <Widget>[Text(participants)]),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Ok'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class CustomListItemForCustomerData extends StatelessWidget {
  const CustomListItemForCustomerData({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textFieldWidth = screenWidth;
    return InkWell(
      onTap: () {
        // Handle the tap event
      },
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (var item in leadContacts)
              SizedBox(
                width: textFieldWidth,
                height: 35,
                child: Container(
                  padding: const EdgeInsets.only(
                    bottom: 0,
                    top: 0,
                    left: 0,
                    right: 0,
                  ),
                  child: ListTile(
                    title: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Row(
                        children: [
                          const Icon(Icons.person_4_outlined, size: 16.0),
                          Expanded(
                            child: Text(
                              item.leadContactName,
                              maxLines: 1, // Set max lines to 1
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                color: Color(0xFF454545),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.add_moderator_outlined, size: 16.0),
                          Expanded(
                            child: Text(
                              item.leadContactDepartment,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                color: Color(0xFF454545),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
