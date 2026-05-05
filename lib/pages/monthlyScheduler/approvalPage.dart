// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/login_screen.dart';
import 'package:http/http.dart' as http;
import '../../classes/dataManager.dart';
import 'package:optima/classes/scheduler.dart';
import '../../sidemenu/sidemenu.dart';

class Hospital {
  String CustomerName;
  String CustomerCode;
  Hospital({required this.CustomerCode, required this.CustomerName});
}

class Distributor {
  String CustomerName;
  String CustomerCode;
  Distributor({required this.CustomerCode, required this.CustomerName});
}

List<Hospital> hspList = [];
List<Distributor> distListWeb = [];
List<Map<String, dynamic>> customerList = [];
String deviceOrientation = "";

bool chartDataLoaded = false;
bool scheduleCompleted = false;
int _selectedPriority = 3;

List<ScheduleParticipant> participantListMaster = [];

class SchedulerApproval extends StatefulWidget {
  const SchedulerApproval({super.key});

  @override
  State<SchedulerApproval> createState() => _SchedulerApprovalState();
}

class SchedulerApprovalProviderForApproval with ChangeNotifier {
  List<MonthlySchedule> _monthlySchedule = [];
  List<MonthlySchedule> get monthlySchedule => _monthlySchedule;
  void updateMonthlyScheduler(List<MonthlySchedule> newMonthlySchedule) {
    _monthlySchedule = newMonthlySchedule;
    notifyListeners();
  }
}

class _SchedulerApprovalState extends State<SchedulerApproval> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<ScheduleParticipant> monthlyParticipantList = [];
  List<ScheduleParticipant> selectedMonthlyParticipantList = [];
  List<ScheduleParticipant> initialParticipantMonthly = [];
  List<Map<String, dynamic>> participantList = [];
  List<MonthlySchedule> tmpScheduleList = [];
  List<MonthlySchedule> monthlyScheduleList = [];
  DateTime selectedDate = DateTime.now();
  final TextEditingController participantController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController distributorController = TextEditingController();
  final TextEditingController othersController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  late Future<void> loadDataFuture;
  int _selectedIndex = 0;
  int scheduleID = 0;

  String selectedOption = '';
  String selectedHospitalId = "";
  String selectedHospitalName = "";
  String selectedOption2 = '';
  String selectedDistributorName = "";
  String selectedDistributorId = "";
  var monthlyHospitalKey = GlobalKey();
  var monthlyDistributorKey = GlobalKey();
  List<Map<String, dynamic>> distributorList = [];
  String userId = "";
  var participantKey = GlobalKey();
  late List<bool> _checked;
  List<String> _reasons = [];
  final TextEditingController _reasonController = TextEditingController();

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  DateTime selectedMonth = DateTime.now();

  Future<void> selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null &&
        (picked.month != selectedMonth.month ||
            picked.year != selectedMonth.year)) {
      setState(() {
        selectedMonth = picked;
      });
    }
  }

  List<Hospital> convertCustomerList(List<Map<String, dynamic>> customerList) {
    return customerList
        .map(
          (map) => Hospital(
            CustomerCode: map['CustomerCode']?.toString() ?? '',
            CustomerName: map['CustomerName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  List<ScheduleParticipant> convertParticipantList(
    List<Map<String, dynamic>> participantList,
  ) {
    return participantList.map((participant) {
      return ScheduleParticipant(
        scheduleParticipantId: 0,
        scheduleParticipantMasterId: 0,
        scheduleParticipantUserId:
            int.tryParse(participant["ParticipantId"].toString()) ?? 0,
        scheduleParticipantUserName: participant["ParticipantName"].toString(),
      );
    }).toList();
  }

  Future<List<Hospital>> getCustomer(String search) async {
    List<Hospital> hospitalList = convertCustomerList(customerList);
    List<Hospital> filteredHospitals = hospitalList
        .where(
          (element) =>
              element.CustomerName.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();

    return filteredHospitals;
  }

  Future<void> _loadCustomer(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectcustomermaster';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          final List data = jsonDecode(response.body)["Data"];
          List<Map<String, dynamic>> newCustomerList = [];
          for (var item in data) {
            final cust = {
              "CustomerCode": item["CustomerCode"],
              "CustomerName": item["CustomerName"],
            };
            newCustomerList.add(cust);
          }
          setState(() {
            customerList = newCustomerList;
            hspList = convertCustomerList(customerList);
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
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        final snackBar = SnackBar(
          content: Text('HTTP Error: ${response.statusCode}'),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text(e.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadParticipant(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
    };
    const apiUrl = '${ApiHelper.baseUrl}loadparticipant';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          final List data = jsonDecode(response.body)["Data"];
          List<Map<String, dynamic>> newParticipantList = [];
          for (var item in data[0]) {
            final participant = {
              "ParticipantId": item["ParticipantId"].toString(),
              "ParticipantName": item["ParticipantName"].toString(),
            };
            newParticipantList.add(participant);
          }
          setState(() {
            participantList = newParticipantList;
            monthlyParticipantList = convertParticipantList(participantList);
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
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            const snackBar = SnackBar(
              content: Text('Participant loading failed'),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        const snackBar = SnackBar(content: Text('Participant loading failed'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('$e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loadCustomer(userId, userJwtToken, userMailID);
    await _loadParticipant(userId, userJwtToken, userMailID);

    await _loadMonthlyScheduler(userId, userJwtToken, userMailID);
    setState(() {
      scheduleCompleted = isMonthlyScheduleComplete(
        DataManager.readSelectedDateCalendar() ?? DateTime.now(),
      );
      chartDataLoaded = true;
    });
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  void clearVariables() async {
    setState(() {
      hospitalController.clear();
      distributorController.clear();
      othersController.clear();
      remarksController.clear();
      othersController.text = "";
      remarksController.text = "";
      selectedMonthlyParticipantList = [];
      monthlyParticipantList = [];
      monthlyParticipantList = convertParticipantList(participantList);
      _selectedPriority = 3;
      monthlyScheduleList = tmpScheduleList;
      scheduleID = 0;
      DateTime parsedDate = DateFormat(
        'yyyy/MM/dd',
      ).parse(DateFormat('yyyy/MM/dd').format(DateTime.now()));
      DataManager.saveSelectedDateCalendar(parsedDate);
      selectedDate = parsedDate;
    });
  }

  void addDataToList() async {
    final hospitalName = hospitalController.text;
    final distributorName = distributorController.text;
    final othersPlaceOfVisit = othersController.text;

    selectedDate = DataManager.readSelectedDateCalendar()!;
    final newSchedule = MonthlySchedule(
      scheduledUser: "",
      scheduleID: scheduleID,
      scheduleUserId: int.tryParse(userId) ?? 0,
      scheduleDate: DateFormat('yyyy/MM/dd').format(selectedDate),
      scheduleCustomerCode: _selectedIndex == 0
          ? selectedHospitalId
          : _selectedIndex == 1
          ? selectedDistributorId
          : '',
      scheduleCustomerName: _selectedIndex == 0
          ? hospitalName
          : _selectedIndex == 1
          ? distributorName
          : othersPlaceOfVisit,
      scheduleCustomerType: _selectedIndex == 0
          ? 'H'
          : _selectedIndex == 1
          ? 'D'
          : 'O',
      scheduleRemarks: remarksController.text,
      schedulePriority: _selectedPriority.toString(),
      scheduleStatus: 'Pending', // Default status
      participantList: selectedMonthlyParticipantList,
    );

    setState(() {
      monthlyScheduleList.add(newSchedule);
      monthlyScheduleList.sort((a, b) {
        DateTime dateA = DateFormat('dd/MM/yyyy').parse(a.scheduleDate);
        DateTime dateB = DateFormat('dd/MM/yyyy').parse(b.scheduleDate);
        return dateB.compareTo(dateA); // DESC
      });
    });
    try {
      setState(() {
        scheduleCompleted = isMonthlyScheduleComplete(
          DataManager.readSelectedDateCalendar() ?? DateTime.now(),
        );
      });
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void addDataToListWhenClear() async {
    final hospitalName = hospitalController.text;
    final distributorName = distributorController.text;
    final othersPlaceOfVisit = othersController.text;

    selectedDate = DataManager.readSelectedDateCalendar()!;
    final newSchedule = MonthlySchedule(
      scheduleID: scheduleID,
      scheduledUser: "",
      scheduleUserId: int.tryParse(userId) ?? 0,
      scheduleDate: DateFormat('yyyy/MM/dd').format(selectedDate),
      scheduleCustomerCode: _selectedIndex == 0
          ? selectedHospitalId
          : _selectedIndex == 1
          ? selectedDistributorId
          : '',
      scheduleCustomerName: _selectedIndex == 0
          ? hospitalName
          : _selectedIndex == 1
          ? distributorName
          : othersPlaceOfVisit,
      scheduleCustomerType: _selectedIndex == 0
          ? 'H'
          : _selectedIndex == 1
          ? 'D'
          : 'O',
      scheduleRemarks: remarksController.text,
      schedulePriority: _selectedPriority.toString(),
      scheduleStatus: 'Pending', // Default status
      participantList: selectedMonthlyParticipantList,
    );

    setState(() {
      monthlyScheduleList.add(newSchedule);
      monthlyScheduleList.sort((a, b) {
        DateTime dateA = DateFormat('dd/MM/yyyy').parse(a.scheduleDate);
        DateTime dateB = DateFormat('dd/MM/yyyy').parse(b.scheduleDate);
        return dateB.compareTo(dateA); // DESC
      });
    });
  }

  void loadContactDetails(MonthlySchedule item) {
    setState(() {
      scheduleID = item.scheduleID;
      if (item.scheduleCustomerType == "H") {
        _selectedIndex = 0;
        selectedHospitalId = item.scheduleCustomerCode;
        hospitalController.text = item.scheduleCustomerName;
      } else if (item.scheduleCustomerType == "D") {
        _selectedIndex = 1;
        selectedDistributorId = item.scheduleCustomerCode;
        distributorController.text = item.scheduleCustomerName;
      } else {
        _selectedIndex = 2;
        othersController.text = item.scheduleCustomerName;
      }
      remarksController.text = item.scheduleRemarks;
      selectedMonthlyParticipantList = item.participantList;
      _selectedPriority = int.tryParse(item.schedulePriority) ?? 3;
      DataManager.saveSelectedDateCalendar(
        DateFormat('yyyy/MM/dd').parse(item.scheduleDate),
      );
      selectedDate = DateFormat('yyyy/MM/dd').parse(item.scheduleDate);
    });
  }

  String previousMonthLastDay(DateTime date) {
    final lastDayPrevMonth = DateTime(date.year, date.month, 0);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final y = lastDayPrevMonth.year;
    final m = twoDigits(lastDayPrevMonth.month);
    final d = twoDigits(lastDayPrevMonth.day);

    return '$y-$m-$d';
  }

  String nextMonthLastDay(DateTime date) {
    // Add 2 months and subtract 1 day to get the last day of next month
    final lastDayNextMonth = DateTime(date.year, date.month + 2, 0);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final y = lastDayNextMonth.year;
    final m = twoDigits(lastDayNextMonth.month);
    final d = twoDigits(lastDayNextMonth.day);

    return '$y-$m-$d';
  }

  Future<void> _loadMonthlyScheduler(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'GivenDate': nextMonthLastDay(DateTime.now()),
      'ScheduleStatus': 'P',
    };
    const apiUrl = '${ApiHelper.baseUrl}loadmonthlyschedulerforapproval';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
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
                    .read<SchedulerApprovalProviderForApproval>()
                    .updateMonthlyScheduler(newMonthlySchedule);
                monthlyScheduleList = newMonthlySchedule;
                tmpScheduleList = monthlyScheduleList;
                _checked = List<bool>.filled(monthlyScheduleList.length, true);
                _reasons = List<String>.filled(monthlyScheduleList.length, '');
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
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        const snackBar = SnackBar(
          content: Text('Monthly schedules are not available.'),
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

  bool isMonthlyScheduleComplete(DateTime selectedDate) {
    final year = selectedDate.year;
    final month = selectedDate.month;
    final lastDay = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= lastDay; day++) {
      final currentDate = DateTime(year, month, day);

      // Skip Sundays
      if (currentDate.weekday == DateTime.sunday) continue;

      final formattedDate = DateFormat('dd/MM/yyyy').format(currentDate);

      final exists = monthlyScheduleList.any(
        (schedule) => schedule.scheduleDate == formattedDate,
      );

      if (!exists) {
        return false;
      }
    }
    return true;
  }

  Future<List<ScheduleParticipant>> getASM(String search) async {
    participantListMaster = monthlyParticipantList
        .map(
          (item) => ScheduleParticipant(
            scheduleParticipantId: item.scheduleParticipantId,
            scheduleParticipantMasterId: item.scheduleParticipantMasterId,
            scheduleParticipantUserId: item.scheduleParticipantUserId,
            scheduleParticipantUserName: item.scheduleParticipantUserName,
          ),
        )
        .toList();

    participantListMaster = participantListMaster.toSet().toList();
    List<ScheduleParticipant> filteredList = participantListMaster
        .where(
          (element) => element.scheduleParticipantUserName
              .toLowerCase()
              .startsWith(search.toLowerCase()),
        )
        .toList();

    return filteredList;
  }

  @override
  void initState() {
    super.initState();
    monthlyParticipantList = [];

    if (isUserLoggedIn) {
      loadDataFuture = loadData();
    }
    selectedDate = DataManager.readSelectedDateCalendar() ?? DateTime.now();
    _checked = List<bool>.filled(monthlyScheduleList.length, true);
    _reasons = List<String>.filled(monthlyScheduleList.length, '');
  }

  @override
  void dispose() {
    participantController.dispose();
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
    return chartDataLoaded == true
        ? Scaffold(
            key: _scaffoldKey,
            drawer: const SideMenu(),
            appBar: AppBar(
              automaticallyImplyLeading: true,
              backgroundColor: Colors.white,
              elevation: 0.0,
              title: const Text(
                "Monthly Schedule Approval",
                style: TextStyle(
                  color: Colors.blue,
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined),
                  color: const Color(0xFF454545),
                  onPressed: () {
                    selectMonth(context);
                  },
                ),
              ],
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              keyboardDismissBehavior: kIsWeb
                  ? ScrollViewKeyboardDismissBehavior.manual
                  : ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 373,
                    child: SingleChildScrollView(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(
                          top: 20,
                          left: 10,
                          right: 10,
                        ),
                        child: Column(
                          children: <Widget>[
                            kIsWeb
                                ? RawAutocomplete<ScheduleParticipant>(
                                    textEditingController:
                                        participantController,
                                    optionsBuilder: (TextEditingValue val) {
                                      return monthlyParticipantList.where(
                                        (user) => user
                                            .scheduleParticipantUserName
                                            .toLowerCase()
                                            .contains(val.text.toLowerCase()),
                                      );
                                    },
                                    displayStringForOption:
                                        (ScheduleParticipant option) =>
                                            option.scheduleParticipantUserName,
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
                                            onSubmitted: (value) =>
                                                onFieldSubmitted(),
                                            decoration: InputDecoration(
                                              labelText: 'Search',
                                              labelStyle: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF8F8F8F),
                                              ),
                                              suffixIcon: IconButton(
                                                icon:
                                                    participantController
                                                            .text ==
                                                        ""
                                                    ? const Icon(
                                                        Icons.search,
                                                        color: Color(
                                                          0xff2ca9df,
                                                        ),
                                                      )
                                                    : const Icon(Icons.clear),
                                                onPressed: () {
                                                  setState(() {
                                                    selectedDistributorId = "";
                                                    selectedDistributorName =
                                                        "";
                                                    participantController
                                                        .clear();
                                                    monthlyScheduleList.clear();
                                                  });
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                    onSelected: (ScheduleParticipant value) {
                                      setState(() {
                                        participantController.text =
                                            value.scheduleParticipantUserName;
                                      });
                                    },
                                    optionsViewBuilder:
                                        (
                                          BuildContext context,
                                          void Function(ScheduleParticipant)
                                          onSelected,
                                          Iterable<ScheduleParticipant> options,
                                        ) {
                                          return Material(
                                            elevation: 4.0,
                                            child: Container(
                                              constraints: const BoxConstraints(
                                                maxHeight: 200,
                                              ),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                physics:
                                                    const ClampingScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                itemBuilder:
                                                    (
                                                      BuildContext context,
                                                      int index,
                                                    ) {
                                                      final ScheduleParticipant
                                                      option = options
                                                          .elementAt(index);
                                                      return GestureDetector(
                                                        onTap: () {
                                                          onSelected(option);
                                                        },
                                                        child: ListTile(
                                                          title: Text(
                                                            option
                                                                .scheduleParticipantUserName,
                                                          ),
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
                                          : (containerDropDownHeight / 1.5)
                                                .clamp(48.0, double.infinity),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: AsyncAutocomplete<ScheduleParticipant>(
                                              onChanged: (s) {
                                                setState(() {
                                                  participantController.text =
                                                      s;
                                                });
                                              },
                                              onSaved: (s) {
                                                setState(() {
                                                  participantController.text =
                                                      s!;
                                                });
                                              },
                                              maxListHeight:
                                                  deviceOrientation ==
                                                      "Portrait"
                                                  ? 370
                                                  : 220,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.only(
                                                      left: 0,
                                                      right: 30,
                                                      top: 0,
                                                      bottom: 0,
                                                    ),
                                                border: UnderlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                hintText: 'Search',
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
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        6.0,
                                                      ),
                                                ),
                                              ),
                                              controller: participantController,
                                              inputKey: participantKey,
                                              onTapItem:
                                                  (
                                                    ScheduleParticipant users,
                                                  ) async {
                                                    setState(() {
                                                      participantController
                                                          .text = users
                                                          .scheduleParticipantUserName;
                                                    });
                                                    chartDataLoaded = false;
                                                    final prefs =
                                                        await SharedPreferences.getInstance();
                                                    userId = users
                                                        .scheduleParticipantUserId
                                                        .toString();
                                                    final userJwtToken =
                                                        prefs.getString(
                                                          'userJwtToken',
                                                        ) ??
                                                        '';
                                                    final userMailID =
                                                        prefs.getString(
                                                          'userMailID',
                                                        ) ??
                                                        '';
                                                    await _loadMonthlyScheduler(
                                                      userId,
                                                      userJwtToken,
                                                      userMailID,
                                                    );
                                                    setState(() {
                                                      chartDataLoaded = true;
                                                    });
                                                  },
                                              suggestionBuilder: (data) => ListTile(
                                                title: Text(
                                                  data.scheduleParticipantUserName,
                                                ),
                                              ),
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
                                                      monthlyScheduleList
                                                          .clear();
                                                      selectedDistributorId =
                                                          "";
                                                      selectedDistributorName =
                                                          "";
                                                      participantController
                                                          .clear();
                                                      getASM("");
                                                    });
                                                  },
                                                  child:
                                                      participantController
                                                              .text ==
                                                          ""
                                                      ? Container(
                                                          decoration:
                                                              const BoxDecoration(
                                                                color: Colors
                                                                    .transparent,
                                                              ),
                                                          child: const Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                  top: 14,
                                                                  right: 2,
                                                                ),
                                                            child: Icon(
                                                              Icons.search,
                                                              color: Color(
                                                                0xff2ca9df,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : Container(
                                                          decoration:
                                                              const BoxDecoration(
                                                                color: Colors
                                                                    .transparent,
                                                              ),
                                                          child: const Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                  top: 14,
                                                                  right: 2,
                                                                ),
                                                            child: Icon(
                                                              Icons
                                                                  .cancel_outlined,
                                                              color: Color(
                                                                0xff2ca9df,
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
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: monthlyScheduleList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final inputFormat = DateFormat('yyyy/MM/dd');
                        final outputFormat = DateFormat('dd/MM/yyyy');

                        DateTime dateTime = inputFormat.parse(
                          monthlyScheduleList[index].scheduleDate,
                        );

                        String filterDate = outputFormat.format(dateTime);
                        return Column(
                          children: <Widget>[
                            SizedBox(
                              width: 375,
                              child: Container(
                                color: const Color(0xFFefefef),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Column(
                                    //   mainAxisAlignment:
                                    //   MainAxisAlignment.center,
                                    //   crossAxisAlignment:
                                    //   CrossAxisAlignment.center,
                                    //   children: [
                                    //     Padding(
                                    //         padding: const EdgeInsets.only(
                                    //             left: 8.0),
                                    //         child: Container(
                                    //           height: 40,
                                    //           color: Colors.white,
                                    //           child: Center(
                                    //               child: Padding(
                                    //                 padding:
                                    //                 const EdgeInsets.all(8.0),
                                    //                 child: Text(
                                    //                   monthlyScheduleList[index]
                                    //                       .scheduleDate
                                    //                       .toString()
                                    //                       .substring(8, 10),
                                    //                 ),
                                    //               )),
                                    //         )),
                                    //   ],
                                    // ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 10),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                          ),
                                          child: Center(
                                            child: Text(filterDate.toString()),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                          ),
                                          child: Text(
                                            monthlyScheduleList[index]
                                                .scheduleCustomerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xff454545),
                                              fontFamily: "Poppins",
                                            ),
                                          ),
                                        ),
                                        // Padding(
                                        //   padding:
                                        //   const EdgeInsets
                                        //       .only(
                                        //       left:
                                        //       8.0),
                                        //   child: Text(
                                        //     monthlyScheduleList[
                                        //     index]
                                        //         .scheduledUser,
                                        //     style: const TextStyle(
                                        //         fontSize:
                                        //         14,
                                        //         fontWeight: FontWeight.w300,
                                        //         color: Color(
                                        //             0xff454545),
                                        //         fontFamily:
                                        //         "Poppins"),
                                        //   ),
                                        // ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                          ),
                                          child: Text(
                                            monthlyScheduleList[index]
                                                .scheduleRemarks,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff454545),
                                              fontFamily: "Poppins",
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    Expanded(
                                      child: ListTile(
                                        title: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [],
                                        ),
                                        subtitle: _checked[index]
                                            ? null
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (_reasons[index]
                                                      .isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 8.0,
                                                          ),
                                                      child: Text(
                                                        'Reason: ${_reasons[index]}',
                                                        style: const TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    Checkbox(
                                      value: _checked[index],
                                      onChanged: (checked) {
                                        if (checked == false) {
                                          _reasonController.clear();
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Please enter a reason',
                                              ),
                                              content: TextField(
                                                controller: _reasonController,
                                                decoration:
                                                    const InputDecoration(
                                                      hintText: 'Reason?',
                                                    ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _checked[index] = false;
                                                      _reasons[index] =
                                                          _reasonController
                                                              .text;
                                                    });
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('OK'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          setState(() {
                                            _checked[index] = true;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Center(
                  //   child: ElevatedButton(
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: const Color(0xff2ca9df),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(5.0),
                  //       ),
                  //     ),
                  //     onPressed: scheduleCompleted
                  //         ? () {
                  //       // Save logic here
                  //     }
                  //         : null, // Disabled if not complete
                  //     child: const SizedBox(
                  //       width: 400,
                  //       child: Center(
                  //         child: Text(
                  //           "Save",
                  //           style: TextStyle(fontSize: 14, color: Colors.white),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          )
        : const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.blue)),
          );
  }

  Widget buildSelectableText(int index, String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Container(
          padding: const EdgeInsets.all(10),
          color: _selectedIndex == index
              ? const Color(0xff2ca9df)
              : const Color(0xFFCFCFCF),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Poppins",
              color: _selectedIndex == index
                  ? Colors.white
                  : const Color(0xFF8F8F8F),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
