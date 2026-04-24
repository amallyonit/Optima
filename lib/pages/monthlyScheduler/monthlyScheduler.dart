// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';
import 'package:optima/sidemenu/sidemenu.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:optima/pages/monthlyScheduler/monthlyCalender.dart';
import '../../classes/dataManager.dart';
import 'package:optima/classes/scheduler.dart';

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
bool editingAllowed = false;
int _selectedPriority = 3;
String saveStatus = "";
final _calendarKey = GlobalKey<MonthlyCalendarState>();
// GlobalKey<FormFieldState> _multiSelectKey = GlobalKey<FormFieldState>();

class MonthlyScheduler extends StatefulWidget {
  const MonthlyScheduler({super.key});

  @override
  State<MonthlyScheduler> createState() => _MonthlySchedulerState();
}

class MonthlySchedulerProvider with ChangeNotifier {
  List<MonthlySchedule> _monthlySchedule = [];
  List<MonthlySchedule> get monthlySchedule => _monthlySchedule;
  void updateMonthlyScheduler(List<MonthlySchedule> newMonthlySchedule) {
    _monthlySchedule = newMonthlySchedule;
    notifyListeners();
  }
}

class _MonthlySchedulerState extends State<MonthlyScheduler> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<ScheduleParticipant> monthlyParticipantList = [];
  List<ScheduleParticipant> selectedMonthlyParticipantList = [];
  List<ScheduleParticipant> initialParticipantMonthly = [];
  List<Map<String, dynamic>> participantList = [];
  List<MonthlySchedule> tmpScheduleList = [];
  List<MonthlySchedule> monthlyScheduleList = [];
  DateTime selectedDate = DateTime.now();
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController distributorController = TextEditingController();
  final TextEditingController othersController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  late Future<void> loadDataFuture;
  int _selectedIndex = 0;
  int scheduleID = 0;
  late FocusNode _focus;
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

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  List<Hospital> convertList(List<Map<String, dynamic>> customerList) {
    return customerList
        .map(
          (map) => Hospital(
            CustomerCode: map['CustomerCode']?.toString() ?? '',
            CustomerName: map['CustomerName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  List<ScheduleParticipant> convertToList(
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
    List<Hospital> hospitalList = convertList(customerList);
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
            hspList = convertList(customerList);
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

  Future<void> _loaddistributor(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectdistributormaster';
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
        // int dataLength = data.length;
        if (status && responseJson["Data"].toString().isNotEmpty) {
          final List data = jsonDecode(response.body)["Data"];
          List<Map<String, dynamic>> newDistributorList = [];
          for (var item in data) {
            final dist = {
              "CustomerCode": item["CustomerCode"],
              "CustomerName": item["CustomerName"],
            };
            newDistributorList.add(dist);
          }
          setState(() {
            distributorList = newDistributorList;
            distListWeb = convertDist(distributorList);
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
      final snackBar = SnackBar(content: Text('$e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadparticipant(
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
            monthlyParticipantList = convertToList(participantList);
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
    await _loadmonthlyscheduler(userId, userJwtToken, userMailID);
    await _loadCustomer(userId, userJwtToken, userMailID);
    await _loaddistributor(userId, userJwtToken, userMailID);
    await _loadparticipant(userId, userJwtToken, userMailID);
    setState(() {
      scheduleCompleted = isMonthlyScheduleComplete(
        DataManager.readSelectedDateCalendar() ?? DateTime.now(),
      );
      chartDataLoaded = true;
    });
  }

  Future<void> addSchedule(MonthlySchedule item) async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    final bodyData = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'schedule': item,
    };
    const apiUrl = '${ApiHelper.baseUrl}insertorupdatemonthlyscheduler';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(bodyData),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];

        if (status) {
          const snackBar = SnackBar(
            duration: Duration(seconds: 1),
            content: Text(
              'Added Successfully...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('$e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  List<Distributor> convertDist(List<Map<String, dynamic>> distributorList) {
    return distributorList
        .map(
          (map) => Distributor(
            CustomerCode: map['CustomerCode']?.toString() ?? '',
            CustomerName: map['CustomerName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  Future<List<Distributor>> getDistributor(String search) async {
    List<Distributor> distList = convertDist(distributorList);
    List<Distributor> filteredList = distList
        .where(
          (element) => element.CustomerName.toLowerCase().startsWith(
            search.toLowerCase(),
          ),
        )
        .toList();

    return filteredList;
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
      monthlyParticipantList = convertToList(participantList);
      _selectedPriority = 3;
      monthlyScheduleList = tmpScheduleList;
      scheduleID = 0;
      // DateTime parsedDate = DateFormat('yyyy/MM/dd').parse(
      //   DateFormat('yyyy/MM/dd').format(DateTime.now()),
      // );
      // DataManager.saveSelectedDateCalendar(parsedDate);
      // selectedDate = parsedDate;
      saveStatus = "";
      dateSetFunction();
    });
  }

  bool isScheduleEntryAllowedOld(DateTime scheduleDate) {
    final firstDayOfMonth = DateTime(scheduleDate.year, scheduleDate.month, 1);
    final lastDayOfPreviousMonth = firstDayOfMonth.subtract(
      const Duration(days: 1),
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // ignore time part

    // Allowed only if today is on or before last day of previous month
    return today.isBefore(lastDayOfPreviousMonth) ||
        today.isAtSameMomentAs(lastDayOfPreviousMonth);
  }

  bool isScheduleEntryAllowed(DateTime scheduleDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // ignore time part
    // First day of next month
    final firstDayOfNextMonth = DateTime(today.year, today.month + 1, 1);

    // Last day of current month
    final lastDayOfCurrentMonth = firstDayOfNextMonth.subtract(
      const Duration(days: 1),
    );

    // Allow only if scheduleDate > lastDayOfCurrentMonth
    return scheduleDate.isAfter(lastDayOfCurrentMonth);
  }

  void addDataToList() async {
    selectedDate = DataManager.readSelectedDateCalendar()!;
    // Restriction check
    if (!isScheduleEntryAllowed(selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Cannot create schedule for ${DateFormat('MMMM yyyy').format(selectedDate)}. "
            "It must be entered on or before ${DateFormat('dd MMM yyyy').format(DateTime(selectedDate.year, selectedDate.month, 1).subtract(const Duration(days: 1)))}.",
          ),
        ),
      );
      return;
    }

    final hospitalName = hospitalController.text;
    final distributorName = distributorController.text;
    final othersPlaceOfVisit = othersController.text;

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
      scheduleStatus: 'H', // Default status - Holding
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
      await addSchedule(newSchedule);
      setState(() {
        scheduleCompleted = isMonthlyScheduleComplete(
          DataManager.readSelectedDateCalendar() ?? DateTime.now(),
        );
      });
    } catch (e) {
      // print('Error: $error');
    }
  }

  void addDataToListWhenClear() async {
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
  }

  void loadContactDetails(MonthlySchedule item) {
    final DateTime tmpDate = DateFormat('yyyy/MM/dd').parse(item.scheduleDate);

    if (!isScheduleEntryAllowed(tmpDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Editing not allowed. The schedule for ${DateFormat('MMMM yyyy').format(tmpDate)} "
            "must have been finalized before ${DateFormat('dd MMM yyyy').format(DateTime(tmpDate.year, tmpDate.month, 1).subtract(const Duration(days: 1)))}.",
          ),
        ),
      );
      return;
    }
    setState(() {
      editingAllowed = true;
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

      dateSetFunction();
    });
  }

  Future<void> _loadmonthlyscheduler(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'GivenDate': (DataManager.readSelectedDateCalendar() ?? DateTime.now())
          .toString()
          .split(' ')[0],
      'ScheduleStatus': 'H', // Default status - Holding
    };
    const apiUrl = '${ApiHelper.baseUrl}loadmonthlyscheduler';
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
                context.read<MonthlySchedulerProvider>().updateMonthlyScheduler(
                  newMonthlySchedule,
                );
                monthlyScheduleList = newMonthlySchedule;
                tmpScheduleList = monthlyScheduleList;
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

  void dateSetFunction() {
    _calendarKey.currentState?.reload();
  }

  void saveMonthlyScheduler() async {
    try {
      for (var schedule in monthlyScheduleList) {
        schedule.scheduleStatus = 'P'; // Pending status
        await addSchedule(schedule); // Save schedule
      }

      if (saveStatus != "") {
        final snackBar = SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
            saveStatus,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        // Call setState after all addSchedule calls are complete
        setState(() {
          scheduleCompleted = isMonthlyScheduleComplete(
            DataManager.readSelectedDateCalendar() ?? DateTime.now(),
          );
          monthlyScheduleList = [];
        });
      }
    } catch (e) {
      // Handle the error if needed
    }
  }

  @override
  void initState() {
    _focus = FocusNode();
    super.initState();
    monthlyParticipantList = [];
    if (isUserLoggedIn) {
      loadDataFuture = loadData();
    }
    selectedDate = DataManager.readSelectedDateCalendar() ?? DateTime.now();
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
      containerHeight = screenHeight * 0.08;
    } else {
      containerDropDownHeight = screenHeight * 0.12;
    }
    final participant = monthlyParticipantList
        .map(
          (participant) => MultiSelectItem<ScheduleParticipant>(
            participant,
            participant.scheduleParticipantUserName,
          ),
        )
        .toList();
    return chartDataLoaded == true
        ? Scaffold(
            key: _scaffoldKey,
            drawer: const SideMenu(),
            appBar: AppBar(
              automaticallyImplyLeading: true,
              backgroundColor: Colors.white,
              elevation: 0.0,
              title: const Text(
                "Monthly Scheduler",
                style: TextStyle(
                  color: Colors.blue,
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              keyboardDismissBehavior: kIsWeb
                  ? ScrollViewKeyboardDismissBehavior.manual
                  : ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: MonthlyCalendar(key: _calendarKey),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: buildSelectableText(0, 'Hospital')),
                          Expanded(
                            child: buildSelectableText(1, 'Distributor'),
                          ),
                          Expanded(child: buildSelectableText(2, 'Other')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: _selectedIndex == 1,
                    child: Column(
                      children: [
                        kIsWeb
                            ? RawAutocomplete<Distributor>(
                                textEditingController: distributorController,
                                focusNode: _focus,
                                optionsBuilder: (TextEditingValue val) {
                                  if (val.text == '') {
                                    clearVariables();
                                    return const Iterable<Distributor>.empty();
                                  }
                                  return distListWeb.where((
                                    Distributor option,
                                  ) {
                                    return option.CustomerName.toLowerCase()
                                        .contains(val.text.toLowerCase());
                                  });
                                },
                                displayStringForOption: (Distributor option) =>
                                    option.CustomerName,
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
                                        onSubmitted: (value) {
                                          distributorController.text = value;
                                          setState(() {
                                            selectedOption2 = value;
                                            distributorController.text = value;
                                            selectedDistributorName = value;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Distributor Name',
                                          labelStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF8F8F8F),
                                          ),
                                          suffixIcon: IconButton(
                                            icon:
                                                distributorController.text == ""
                                                ? const Icon(
                                                    Icons.search,
                                                    color: Color(0xff2ca9df),
                                                  )
                                                : const Icon(Icons.clear),
                                            onPressed: () {
                                              addDataToListWhenClear();
                                              selectedOption2 = '';
                                              selectedDistributorId = "";
                                              selectedDistributorName = "";
                                              distributorController.clear();
                                              clearVariables();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                onSelected: (Distributor value) {
                                  distributorController.text =
                                      value.CustomerName;
                                  setState(() {
                                    selectedOption2 = value.CustomerName;
                                    distributorController.text =
                                        value.CustomerName;
                                    var customer = distributorList.firstWhere(
                                      (map) =>
                                          map['CustomerName'] ==
                                          value.CustomerName,
                                      // orElse: () =>
                                      //     <String, dynamic>{'CustomerCode': null},
                                    );
                                    selectedDistributorId =
                                        customer['CustomerCode'].toString();
                                    selectedDistributorName =
                                        value.CustomerName;
                                  });
                                },
                                optionsViewBuilder:
                                    (
                                      BuildContext context,
                                      void Function(Distributor) onSelected,
                                      Iterable<Distributor> options,
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
                                                  final Distributor option =
                                                      options.elementAt(index);
                                                  return GestureDetector(
                                                    onTap: () {
                                                      onSelected(option);
                                                    },
                                                    child: ListTile(
                                                      title: Text(
                                                        option.CustomerName,
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
                                  left: 12.0,
                                  right: 12.0,
                                ),
                                child: SizedBox(
                                  height: deviceOrientation == "Portrait"
                                      ? containerHeight
                                      : containerDropDownHeight / 1.5,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: AsyncAutocomplete<Distributor>(
                                          onChanged: (s) {
                                            setState(() {
                                              distributorController.text == s;
                                            });
                                          },
                                          onSaved: (s) {
                                            setState(() {
                                              distributorController.text == s;
                                            });
                                          },
                                          maxListHeight:
                                              deviceOrientation == "Portrait"
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
                                            hintText: 'Distributor Name',
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
                                                  BorderRadius.circular(6.0),
                                            ),
                                          ),
                                          controller: distributorController,
                                          inputKey: monthlyDistributorKey,
                                          onTapItem: (Distributor distributor) async {
                                            setState(() {
                                              selectedOption2 =
                                                  distributor.CustomerName;
                                              distributorController.text =
                                                  distributor.CustomerName;
                                              var customer = distributorList
                                                  .firstWhere(
                                                    (map) =>
                                                        map['CustomerName'] ==
                                                        distributor
                                                            .CustomerName,
                                                    // orElse: () =>
                                                    //     <String, dynamic>{'CustomerCode': null},
                                                  );
                                              selectedDistributorId =
                                                  customer['CustomerCode']
                                                      .toString();
                                              selectedDistributorName =
                                                  distributor.CustomerName;
                                            });
                                          },
                                          suggestionBuilder: (data) => ListTile(
                                            title: Text(data.CustomerName),
                                          ),
                                          asyncSuggestions: (searchValue) =>
                                              getDistributor(searchValue),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: -1,
                                        child: Visibility(
                                          child: SizedBox(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  addDataToListWhenClear();
                                                  selectedOption2 = '';
                                                  selectedDistributorId = "";
                                                  selectedDistributorName = "";
                                                  distributorController.clear();
                                                  clearVariables();
                                                });
                                              },
                                              child:
                                                  distributorController.text ==
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
                                                          Icons.cancel_outlined,
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
                  Visibility(
                    visible: _selectedIndex == 0,
                    child: Column(
                      children: [
                        kIsWeb
                            ? RawAutocomplete<Hospital>(
                                textEditingController: hospitalController,
                                focusNode: _focus,
                                optionsBuilder: (TextEditingValue val) {
                                  if (val.text == '') {
                                    clearVariables();
                                    return const Iterable<Hospital>.empty();
                                  }
                                  return hspList.where((Hospital option) {
                                    return option.CustomerName.toLowerCase()
                                        .contains(val.text.toLowerCase());
                                  });
                                },
                                displayStringForOption: (Hospital option) =>
                                    option.CustomerName,
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
                                          labelText: 'Hospital Name',
                                          labelStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF8F8F8F),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: hospitalController.text == ""
                                                ? const Icon(
                                                    Icons.search,
                                                    color: Color(0xff2ca9df),
                                                  )
                                                : const Icon(Icons.clear),
                                            onPressed: () {
                                              addDataToListWhenClear();
                                              selectedOption = '';
                                              selectedHospitalId = "";
                                              hospitalController.clear();
                                              clearVariables();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                onSelected: (Hospital value) {
                                  hospitalController.text = value.CustomerName;
                                  setState(() {
                                    selectedOption = value.CustomerName;
                                    hospitalController.text =
                                        value.CustomerName;
                                    var customer = customerList.firstWhere(
                                      (map) =>
                                          map['CustomerName'] ==
                                          value.CustomerName,
                                    );
                                    selectedHospitalId =
                                        customer['CustomerCode'].toString();
                                    selectedHospitalName = value.CustomerName;
                                  });
                                },
                                optionsViewBuilder:
                                    (
                                      BuildContext context,
                                      void Function(Hospital) onSelected,
                                      Iterable<Hospital> options,
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
                                                  final Hospital option =
                                                      options.elementAt(index);
                                                  return GestureDetector(
                                                    onTap: () {
                                                      onSelected(option);
                                                    },
                                                    child: ListTile(
                                                      title: Text(
                                                        option.CustomerName,
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
                                  left: 12.0,
                                  right: 12.0,
                                ),
                                child: SizedBox(
                                  height: deviceOrientation == "Portrait"
                                      ? containerHeight
                                      : containerDropDownHeight / 1.5,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: AsyncAutocomplete<Hospital>(
                                          onChanged: (s) {
                                            setState(() {
                                              hospitalController.text == s;
                                            });
                                          },
                                          onSaved: (s) {
                                            setState(() {
                                              hospitalController.text == s;
                                            });
                                          },
                                          focusNode: _focus,
                                          maxListHeight:
                                              deviceOrientation == "Portrait"
                                              ? 370
                                              : 220,
                                          decoration: InputDecoration(
                                            border: UnderlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            labelText: 'Hospital Name',
                                            labelStyle: const TextStyle(
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
                                                  BorderRadius.circular(6.0),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.only(
                                                  left: 0,
                                                  right: 30,
                                                  top: 0,
                                                  bottom: 0,
                                                ),
                                          ),
                                          controller: hospitalController,
                                          inputKey: monthlyHospitalKey,
                                          onTapItem: (Hospital hospital) async {
                                            setState(() {
                                              selectedOption =
                                                  hospital.CustomerName;
                                              hospitalController.text =
                                                  hospital.CustomerName;
                                              var customer = customerList
                                                  .firstWhere(
                                                    (map) =>
                                                        map['CustomerName'] ==
                                                        hospital.CustomerName,
                                                  );
                                              selectedHospitalId =
                                                  customer['CustomerCode']
                                                      .toString();
                                              selectedHospitalName =
                                                  hospital.CustomerName;
                                            });
                                          },
                                          suggestionBuilder: (data) => ListTile(
                                            title: Text(
                                              data.CustomerName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          asyncSuggestions: (searchValue) =>
                                              getCustomer(searchValue),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: -1,
                                        child: Visibility(
                                          child: SizedBox(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  addDataToListWhenClear();
                                                  selectedOption = '';
                                                  selectedHospitalId = "";
                                                  hospitalController.clear();
                                                  clearVariables();
                                                });
                                                // loadContacs();
                                              },
                                              child:
                                                  hospitalController.text == ""
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
                                                          Icons.close_rounded,
                                                          size: 20,
                                                          color: Colors.grey,
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
                  Visibility(
                    visible: _selectedIndex == 2,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 12.0,
                        right: 12.0,
                        bottom: 0,
                      ),
                      child: TextField(
                        controller: othersController,
                        decoration: const InputDecoration(
                          hintText: "Place of Visit",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8F8F8F),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 150,
                    width: 373,
                    child: SingleChildScrollView(
                      child: Container(
                        color: const Color.fromARGB(255, 242, 240, 240),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(
                          top: 20,
                          left: 10,
                          right: 10,
                        ),
                        child: Column(
                          children: <Widget>[
                            MultiSelectDialogField(
                              // key: _multiSelectKey,
                              checkColor: Colors.white,
                              chipDisplay:
                                  MultiSelectChipDisplay<ScheduleParticipant>(
                                    chipColor: const Color(0xff2ca9df),
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    onTap: (selected) {
                                      setState(() {
                                        selectedMonthlyParticipantList.remove(
                                          selected,
                                        );
                                      });
                                    },
                                  ),
                              searchable: true,
                              listType: MultiSelectListType.LIST,
                              initialValue: selectedMonthlyParticipantList,
                              separateSelectedItems: false,
                              items: participant,
                              title: const Text("Participants"),
                              selectedColor: const Color(0xff2ca9df),
                              buttonIcon: const Icon(
                                Icons.search,
                                color: Color(0xff2ca9df),
                              ),
                              buttonText: const Text(
                                "Participants",
                                style: TextStyle(
                                  color: Color(0xFF454545),
                                  fontFamily: "Poppins",
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                              // onConfirm: (results) {
                              //   setState(() {
                              //     selectedMonthlyParticipantList = results;
                              //   });
                              // },
                              onConfirm: (results) {
                                setState(() {
                                  selectedMonthlyParticipantList =
                                      List<ScheduleParticipant>.from(results);
                                });
                              },
                              selectedItemsTextStyle: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                    child: TextField(
                      controller: remarksController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        labelText: "Remarks",
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8F8F8F),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 1, color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.only(
                          left: 15,
                          right: 0,
                          top: 15,
                          bottom: 0,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Priority:"),
                      Radio<int>(
                        value: 1,
                        groupValue: _selectedPriority,
                        activeColor: Colors.red,
                        onChanged: (int? value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                      ),
                      const Text('High'),
                      Radio<int>(
                        value: 2,
                        groupValue: _selectedPriority,
                        activeColor: Colors.orange,
                        onChanged: (int? value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                      ),
                      const Text('Medium'),
                      Radio<int>(
                        value: 3,
                        groupValue: _selectedPriority,
                        activeColor: Colors.green,
                        onChanged: (int? value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                      ),
                      const Text('Normal'),
                    ],
                  ),
                  Center(
                    child: SizedBox(
                      width: 125,
                      child: InkWell(
                        onTap: () {
                          if (hospitalController.text.trim().isEmpty &&
                              distributorController.text.trim().isEmpty &&
                              othersController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account Name cannot be empty'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          addDataToList();
                          clearVariables();
                        },
                        child: Container(
                          width: 0,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2CA9DF),
                            borderRadius: BorderRadius.circular(0.0),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: monthlyScheduleList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final participants =
                            monthlyScheduleList[index].participantList;
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [SizedBox(height: 20)],
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        title: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Center(
                                              child: Text(
                                                filterDate,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                loadContactDetails(
                                                  monthlyScheduleList[index],
                                                );
                                                setState(() {
                                                  if (editingAllowed) {
                                                    monthlyScheduleList.remove(
                                                      monthlyScheduleList[index],
                                                    );
                                                  }
                                                });
                                              },
                                              child: const Icon(
                                                Icons.edit,
                                                size: 16.0,
                                                color: Color(0xff454545),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      monthlyScheduleList[index]
                                                          .scheduleCustomerName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xff454545,
                                                        ),
                                                        fontFamily: "Poppins",
                                                      ),
                                                    ),
                                                    for (var p in participants)
                                                      Text(
                                                        p.scheduleParticipantUserName,
                                                        textAlign:
                                                            TextAlign.left,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w300,
                                                          color: Color(
                                                            0xff454545,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
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
                  ),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2ca9df),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      onPressed: scheduleCompleted
                          ? () {
                              saveMonthlyScheduler();
                            }
                          : null, // Disabled if not complete
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
