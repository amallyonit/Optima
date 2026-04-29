// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:intl/intl.dart';
import 'package:optima/sidemenu/sidemenu.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/login_screen.dart';
import 'package:http/http.dart' as http;
import '../../classes/dataManager.dart';
import 'package:optima/classes/scheduler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';

class CustomerCommon {
  final String name;
  final String code;
  final String type; // H / D

  CustomerCommon({required this.name, required this.code, required this.type});
}

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
String saveStatus = "";

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
  int? editingIndex;
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
  String userName = "";
  String userJwtToken = "";
  String userMailID = "";
  bool isMonthLoading = false;
  stt.SpeechToText? _speech;
  bool _isListening = false;
  Map<int, TextEditingController> remarksControllers = {};
  Timer? _silenceTimer;
  bool _isProcessing = false;
  String selectedLocaleId = "en_IN"; // default mixed language
  bool showLanguageSelector = false;

  List<CustomerCommon> getCombinedCustomerList() {
    List<CustomerCommon> list = [];

    // Hospitals
    for (var item in customerList) {
      list.add(
        CustomerCommon(
          name: item["CustomerName"],
          code: item["CustomerCode"],
          type: "H",
        ),
      );
    }

    // Distributors
    for (var item in distributorList) {
      list.add(
        CustomerCommon(
          name: item["CustomerName"],
          code: item["CustomerCode"],
          type: "D",
        ),
      );
    }

    return list;
  }

  Future<List<CustomerCommon>> searchCustomer(String search) async {
    final list = getCombinedCustomerList();

    return list
        .where(
          (c) =>
              c.name.toLowerCase().contains(search.toLowerCase()) ||
              c.code.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
  }

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
              "Type": "H",
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

  Future<void> _loadDistributor(
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
              "Type": "D",
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
    userName = prefs.getString('userName') ?? '';
    userJwtToken = prefs.getString('userJwtToken') ?? '';
    userMailID = prefs.getString('userMailID') ?? '';
    await _loadMonthlyScheduler(userId, userJwtToken, userMailID);
    await _loadCustomer(userId, userJwtToken, userMailID);
    await _loadDistributor(userId, userJwtToken, userMailID);
    await _loadParticipant(userId, userJwtToken, userMailID);

    selectedDate = DataManager.readSelectedDateCalendar() ?? DateTime.now();
    if (monthlyScheduleList.isEmpty) {
      autoFillMonth();
    }
    await setDefaultParticipant();
    setState(() {
      scheduleCompleted = isMonthlyScheduleComplete(selectedDate);
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

        if (status && item.scheduleStatus != "P") {
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
      monthlyScheduleList = tmpScheduleList;
      scheduleID = 0;
      saveStatus = "";
    });
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

  Future<void> addData(MonthlySchedule newSchedule) async {
    // Restriction check
    if (!isScheduleEntryAllowed(selectedDate)) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                /// Icon
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 32,
                ),

                const SizedBox(height: 10),

                /// Message
                Text(
                  "Cannot create schedule for ${DateFormat('MMMM yyyy').format(selectedDate)}.\n\n"
                  "It must be entered on or before "
                  "${DateFormat('dd MMM yyyy').format(DateTime(selectedDate.year, selectedDate.month, 1).subtract(const Duration(days: 1)))}.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 15),

                /// OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ),
              ],
            ),
          );
        },
      );

      return;
    }

    try {
      await addSchedule(newSchedule);
      setState(() {
        scheduleCompleted = isMonthlyScheduleComplete(selectedDate);
      });
    } catch (e) {
      // print('Error: $error');
    }
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
      'GivenDate': selectedDate.toString().split(' ')[0],
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

  Future<void> setDefaultParticipant() async {
    final defaultUser = monthlyParticipantList.firstWhere(
      (p) => p.scheduleParticipantUserName == userName,
      orElse: () => ScheduleParticipant(
        scheduleParticipantId: 0,
        scheduleParticipantMasterId: 0,
        scheduleParticipantUserId: userId.isNotEmpty
            ? int.tryParse(userId) ?? 0
            : 0,
        scheduleParticipantUserName: userName,
      ),
    );

    for (var item in monthlyScheduleList) {
      if (item.participantList.isEmpty) {
        item.participantList = [defaultUser];
      }
    }

    setState(() {});
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

  void saveMonthlyScheduler() async {
    try {
      bool lastRow = false;
      for (int i = 0; i < monthlyScheduleList.length; i++) {
        var schedule = monthlyScheduleList[i];

        lastRow = i == monthlyScheduleList.length - 1;

        schedule.scheduleStatus = 'P';

        await addSchedule(schedule);
      }
      if (lastRow) {
        saveStatus = "Monthly schedule saved successfully!";
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
          saveStatus = "";
          scheduleCompleted = isMonthlyScheduleComplete(selectedDate);
          monthlyScheduleList = [];
        });
      }
    } catch (e) {
      // Handle the error if needed
    }
  }

  bool isPureEnglish(String text) {
    return RegExp(r'^[a-zA-Z0-9\s.,]+$').hasMatch(text);
  }

  @override
  void initState() {
    super.initState();

    _focus = FocusNode();

    _speech = stt.SpeechToText();
    monthlyParticipantList = [];
    monthlyScheduleList = [];
    _speech!.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListening = false;
          });
        }
      },
    );

    if (isUserLoggedIn) {
      loadDataFuture = loadData();
    }
  }

  Future<void> startListening(MonthlySchedule item, int index) async {
    if (!(_speech?.isAvailable ?? false)) return;

    setState(() => _isListening = true);

    _speech!.listen(
      localeId: selectedLocaleId,
      listenMode: stt.ListenMode.dictation,
      pauseFor: const Duration(seconds: 3), // keep this

      onResult: (result) {
        final text = result.recognizedWords;

        if (text.isNotEmpty) {
          setState(() {
            remarksControllers[index]?.text = text;
            item.scheduleRemarks = text;
          });

          // Reset silence timer every time user speaks
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(seconds: 2), () {
            setState(() {
              _isListening = false;
              _isProcessing = true; // show Processing...
            });
            stopListening(); // force stop after silence
          });
        }
      },
    );
  }

  void stopListening() {
    _silenceTimer?.cancel();
    _speech?.stop();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isListening = false;
          _isProcessing = false; // hide Processing
        });
      }
    });
  }

  Future<void> initSpeech() async {
    _speech ??= stt.SpeechToText();
  }

  void autoFillMonth() {
    DateTime baseDate = selectedDate;

    int year = baseDate.year;
    int month = baseDate.month;

    int lastDay = DateTime(year, month + 1, 0).day;

    /// Collect existing dates
    Set<String> existingDates = monthlyScheduleList
        .map((e) => e.scheduleDate)
        .toSet();

    List<MonthlySchedule> newRows = [];

    for (int day = 1; day <= lastDay; day++) {
      DateTime currentDate = DateTime(year, month, day);

      // Skip Sundays
      if (currentDate.weekday == DateTime.sunday) continue;

      String formatted = DateFormat('yyyy/MM/dd').format(currentDate);

      /// Skip if already exists
      if (existingDates.contains(formatted)) continue;

      newRows.add(
        MonthlySchedule(
          scheduledUser: "",
          scheduleID: 0,
          scheduleUserId: int.tryParse(userId) ?? 0,
          scheduleDate: formatted,
          scheduleCustomerCode: "",
          scheduleCustomerName: "",
          scheduleCustomerType: "H",
          scheduleRemarks: "",
          schedulePriority: "3",
          scheduleStatus: "H",
          participantList: [],
        ),
      );
    }

    setState(() {
      monthlyScheduleList.addAll(newRows);

      /// Sort ASC
      monthlyScheduleList.sort((a, b) {
        DateTime dateA = DateFormat('yyyy/MM/dd').parse(a.scheduleDate);
        DateTime dateB = DateFormat('yyyy/MM/dd').parse(b.scheduleDate);
        return dateA.compareTo(dateB);
      });
    });

    if (mounted && newRows.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${newRows.length} missing days added"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  bool isRowValid(MonthlySchedule item) {
    return item.scheduleDate.isNotEmpty &&
        item.scheduleCustomerName.isNotEmpty &&
        item.scheduleCustomerCode.isNotEmpty &&
        item.schedulePriority.isNotEmpty &&
        item.participantList.isNotEmpty;
  }

  bool get isSaveEnabled {
    int totalDays = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );

    int uniqueDays = monthlyScheduleList
        .map((e) => e.scheduleDate)
        .toSet()
        .length;

    return uniqueDays >= totalDays &&
        monthlyScheduleList.every((e) => isRowValid(e));
  }

  Map<String, List<MonthlySchedule>> groupByDate() {
    Map<String, List<MonthlySchedule>> grouped = {};

    for (var item in monthlyScheduleList) {
      if (!grouped.containsKey(item.scheduleDate)) {
        grouped[item.scheduleDate] = [];
      }
      grouped[item.scheduleDate]!.add(item);
    }

    return grouped;
  }

  void addVisitForDate(String date) {
    final defaultUser = ScheduleParticipant(
      scheduleParticipantId: 0,
      scheduleParticipantMasterId: 0,
      scheduleParticipantUserId: userId.isNotEmpty
          ? int.tryParse(userId) ?? 0
          : 0,
      scheduleParticipantUserName: userName,
    );

    setState(() {
      monthlyScheduleList.add(
        MonthlySchedule(
          scheduledUser: "",
          scheduleID: 0,
          scheduleUserId: int.tryParse(userId) ?? 0,
          scheduleDate: date, // same date
          scheduleCustomerCode: "",
          scheduleCustomerName: "",
          scheduleCustomerType: "H", // default Hospital
          scheduleRemarks: "",
          schedulePriority: "3",
          scheduleStatus: "H",
          participantList: [defaultUser],
        ),
      );
    });
  }

  Future<void> openMonthPicker() async {
    int year = selectedDate.year;

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            width: 320,
            height: 320,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  /// Title
                  const Text(
                    "Select Month",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  /// Year dropdown
                  DropdownButton<int>(
                    value: year,
                    isExpanded: true,
                    items: List.generate(5, (i) {
                      int y = DateTime.now().year - 2 + i;
                      return DropdownMenuItem(
                        value: y,
                        child: Text(y.toString()),
                      );
                    }),
                    onChanged: (val) {
                      setState(() {
                        year = val!;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  /// Month grid
                  Expanded(
                    child: GridView.builder(
                      itemCount: 12,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.5,
                          ),
                      itemBuilder: (context, index) {
                        final m = index + 1;

                        return GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            setState(() {
                              isMonthLoading = true;
                              selectedDate = DateTime(year, m);
                              monthlyScheduleList = [];
                            });

                            try {
                              await _loadMonthlyScheduler(
                                userId,
                                userJwtToken,
                                userMailID,
                              );

                              autoFillMonth();
                              setDefaultParticipant();
                            } catch (e) {
                              // optional error handling
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isMonthLoading = false;
                                });
                              }
                            }
                          },
                          child: Card(
                            color: selectedDate.month == m
                                ? Colors.blue.shade100
                                : null,
                            child: Center(
                              child: Text(
                                DateFormat.MMM().format(DateTime(0, m)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> translateRemarks(MonthlySchedule item, int index) async {
    final text = item.scheduleRemarks;

    if (text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final translator = GoogleTranslator();

      final translation = await translator.translate(text, to: 'en');

      setState(() {
        item.scheduleRemarks = translation.text;
        remarksControllers[index]?.text = translation.text;
      });
    } catch (e) {
      // optional: error handling
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      appBar: AppBar(title: const Text("Monthly Plan")),
      body: FutureBuilder(
        future: loadDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Loading monthly plan..."),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }

          return Stack(
            children: [
              /// Main UI
              Column(
                children: [
                  buildMonthHeader(),
                  buildHeaderBanner(),

                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final grouped = groupByDate();

                        final sortedDates = grouped.keys.toList()
                          ..sort((a, b) {
                            DateTime dateA = DateFormat('yyyy/MM/dd').parse(a);
                            DateTime dateB = DateFormat('yyyy/MM/dd').parse(b);
                            return dateA.compareTo(dateB);
                          });

                        return ListView.builder(
                          itemCount: sortedDates.length,
                          itemBuilder: (context, index) {
                            String date = sortedDates[index];
                            List<MonthlySchedule> items = grouped[date]!;

                            return buildDateGroup(date, items);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              /// Loader overlay
              if (isMonthLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget buildPriorityTag(String priority) {
    Color color;
    String text;

    switch (priority) {
      case "1":
        color = Colors.red;
        text = "Priority: HIGH";
        break;
      case "2":
        color = Colors.orange;
        text = "Priority: MEDIUM";
        break;
      default:
        color = Colors.green;
        text = "Priority: LOW";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildCustomerTag(String scheduleCustomerType) {
    Color tagColor;
    String tagText;

    switch (scheduleCustomerType) {
      case "H":
        tagColor = Colors.blue;
        tagText = "HOSPITAL";
        break;
      case "D":
        tagColor = Colors.green;
        tagText = "DISTRIBUTOR";
        break;
      default:
        tagColor = Colors.orange;
        tagText = "OTHER";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tagText,
        style: TextStyle(color: tagColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildDateGroup(String date, List<MonthlySchedule> items) {
    DateTime parsed = DateFormat('yyyy/MM/dd').parse(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Date Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            DateFormat('dd MMM yyyy').format(parsed),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),

        /// Cards for that date
        ...items.map((item) {
          int index = monthlyScheduleList.indexOf(item);
          return buildScheduleCard(item, index);
        }),

        /// + Add Visit button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextButton.icon(
            onPressed: () => addVisitForDate(date),
            icon: const Icon(Icons.add),
            label: const Text("Add another visit for the day"),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  Widget buildHeaderBanner() {
    int totalDays = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );

    int filledDays = monthlyScheduleList
        .map((e) => e.scheduleDate)
        .toSet()
        .length;

    bool isComplete = filledDays >= totalDays;

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 10),

          Expanded(
            child: Text(
              "Add all your plan entries for the month. Save will be enabled once all dates have entries.",
              style: const TextStyle(fontSize: 13),
            ),
          ),

          const SizedBox(width: 10),

          ElevatedButton.icon(
            onPressed: isSaveEnabled ? saveMonthlyScheduler : null,
            icon: const Icon(Icons.save),
            label: Text("Save ($filledDays/$totalDays)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isComplete ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMonthHeader() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.blue),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: openMonthPicker,
                child: Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.edit_calendar),
            onPressed: openMonthPicker,
          ),
        ],
      ),
    );
  }

  Widget buildScheduleCard(MonthlySchedule item, int index) {
    final isEditing = editingIndex == index;
    final controller = remarksControllers[index] ??= TextEditingController();
    if (controller.text != item.scheduleRemarks) {
      controller.text = item.scheduleRemarks;
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// LEFT → Tags
                Row(
                  children: [
                    buildCustomerTag(item.scheduleCustomerType),
                    const SizedBox(width: 6),
                    buildPriorityTag(item.schedulePriority),
                  ],
                ),

                /// RIGHT → Actions
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isEditing ? Icons.check : Icons.edit,
                        color: Colors.blue,
                      ),
                      onPressed: () async {
                        if (isEditing) {
                          try {
                            await addData(item); // API CALL

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Updated successfully"),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }

                          setState(() {
                            editingIndex = null;
                          });
                        } else {
                          setState(() {
                            editingIndex = index;
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          monthlyScheduleList.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// CUSTOMER
            isEditing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Row → Autocomplete + Tag
                      Row(
                        children: [
                          Expanded(child: buildCustomerField(item)),
                          const SizedBox(width: 6),
                        ],
                      ),

                      const SizedBox(height: 6),

                      /// Other input (ONLY when type = O)
                      if (item.scheduleCustomerType == "O")
                        TextFormField(
                          initialValue: item.scheduleCustomerName,
                          decoration: const InputDecoration(
                            labelText: "Other (if not found)",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setState(() {
                              item.scheduleCustomerName = val;
                              item.scheduleCustomerCode = "";
                              item.scheduleCustomerType = "O";
                            });
                          },
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: Text(item.scheduleCustomerName)),
                      const SizedBox(width: 6),
                    ],
                  ),

            const SizedBox(height: 8),

            /// PARTICIPANTS
            isEditing
                ? buildParticipantsField(item)
                : SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.start, // important
                      spacing: 6,
                      runSpacing: 4,
                      children: item.participantList.map((p) {
                        return Chip(
                          label: Text(
                            p.scheduleParticipantUserName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

            const SizedBox(height: 8),

            /// REMARKS
            isEditing
                ? Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: "Remarks",
                          ),
                          onChanged: (val) {
                            item.scheduleRemarks = val;
                          },
                        ),
                      ),

                      const SizedBox(width: 6),

                      /// Listening indicator
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: VoiceIndicator(
                          isListening: _isListening,
                          isProcessing: _isProcessing,
                        ),
                      ),

                      if (showLanguageSelector)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.language, size: 18),
                          onSelected: (val) {
                            setState(() => selectedLocaleId = val);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: "en_IN",
                              child: Text("English"),
                            ),
                            PopupMenuItem(value: "hi_IN", child: Text("Hindi")),
                            PopupMenuItem(value: "ta_IN", child: Text("Tamil")),
                            PopupMenuItem(
                              value: "kn_IN",
                              child: Text("Kannada"),
                            ),
                            PopupMenuItem(
                              value: "te_IN",
                              child: Text("Telugu"),
                            ),
                            PopupMenuItem(
                              value: "ml_IN",
                              child: Text("Malayalam"),
                            ),
                          ],
                        ),

                      /// Mic button
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : Colors.blue,
                        ),
                        onPressed: () async {
                          if (_isListening) {
                            stopListening();
                          } else {
                            await initSpeech();
                            startListening(item, index);
                          }
                        },
                      ),
                      Text(
                        selectedLocaleId.split("_")[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Remarks text
                      Expanded(
                        child: Text(
                          item.scheduleRemarks,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                      const SizedBox(width: 6),

                      ///  Translate button (ONLY in view mode)
                      IconButton(
                        icon: const Icon(
                          Icons.translate,
                          size: 18,
                          color: Colors.green,
                        ),
                        tooltip: "Translate to English",
                        // onPressed: isPureEnglish(item.scheduleRemarks)
                        //     ? () => translateRemarks(item, index)
                        //     : null,
                        onPressed: () => translateRemarks(item, index),
                      ),
                    ],
                  ),

            const SizedBox(height: 8),

            /// PRIORITY
            isEditing ? buildPriorityDropdown(item) : SizedBox(height: 0),
          ],
        ),
      ),
    );
  }

  Widget buildCustomerField(MonthlySchedule item) {
    final controller = TextEditingController();
    controller.text = item.scheduleCustomerName;

    return AsyncAutocomplete<CustomerCommon>(
      controller: controller,

      asyncSuggestions: (searchValue) async {
        final results = await searchCustomer(searchValue);

        if (results.isEmpty && searchValue.isNotEmpty) {
          return [CustomerCommon(name: searchValue, code: "", type: "O")];
        }

        return results;
      },

      suggestionBuilder: (customer) {
        return ListTile(
          title: Text(customer.name),
          subtitle: Text(
            "${customer.code} • ${customer.type == "H" ? "🏥 Hospital" : "🏢 Distributor"}",
          ),
        );
      },

      onTapItem: (CustomerCommon customer) {
        setState(() {
          item.scheduleCustomerName = customer.name;
          item.scheduleCustomerCode = customer.code;
          item.scheduleCustomerType = customer.type;
        });

        controller.text = customer.name; //  THIS FIXES UI
      },
    );
  }

  Widget buildParticipantsField(MonthlySchedule item) {
    final TextEditingController controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Chips display
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: item.participantList.map((p) {
            return Chip(
              label: Text(p.scheduleParticipantUserName),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  item.participantList.remove(p);
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 6),

        /// Search + Add
        AsyncAutocomplete<ScheduleParticipant>(
          controller: controller,

          asyncSuggestions: (search) async {
            return monthlyParticipantList
                .where(
                  (p) =>
                      p.scheduleParticipantUserName.toLowerCase().contains(
                        search.toLowerCase(),
                      ) &&
                      !item.participantList.contains(p),
                )
                .toList();
          },

          suggestionBuilder: (p) =>
              ListTile(title: Text(p.scheduleParticipantUserName)),

          onTapItem: (ScheduleParticipant selected) {
            setState(() {
              if (!item.participantList.contains(selected)) {
                item.participantList.add(selected);
              }
            });

            controller.clear(); // important UX
          },

          decoration: const InputDecoration(
            hintText: "Add participant",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget buildPriorityDropdown(MonthlySchedule item) {
    return DropdownButtonFormField<int>(
      value: int.tryParse(item.schedulePriority) ?? 3,
      decoration: const InputDecoration(
        labelText: "Priority",
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 1, child: Text("High")),
        DropdownMenuItem(value: 2, child: Text("Medium")),
        DropdownMenuItem(value: 3, child: Text("Low")),
      ],
      onChanged: (val) {
        setState(() {
          item.schedulePriority = val.toString();
        });
      },
    );
  }

  Widget buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: OutlinedButton.icon(
        onPressed: () {
          clearVariables(); // your existing method
        },
        icon: const Icon(Icons.add),
        label: const Text("Add New"),
      ),
    );
  }

  Widget buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: ElevatedButton(
        onPressed: scheduleCompleted ? saveMonthlyScheduler : null,
        child: const Text("Save Monthly Plan"),
      ),
    );
  }

  @override
  void dispose() {
    hospitalController.dispose();
    distributorController.dispose();
    othersController.dispose();
    remarksController.dispose();
    _focus.dispose();
    super.dispose();
  }
}

class VoiceIndicator extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;

  const VoiceIndicator({
    super.key,
    required this.isListening,
    required this.isProcessing,
  });

  @override
  State<VoiceIndicator> createState() => _VoiceIndicatorState();
}

class _VoiceIndicatorState extends State<VoiceIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant VoiceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isListening) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildWaveBar(double heightFactor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Container(
          width: 3,
          height: 10 + (_controller.value * heightFactor),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isListening) {
      return Row(
        key: const ValueKey("listening"),
        children: [
          const SizedBox(width: 4),

          /// Wave animation
          Row(
            children: [
              buildWaveBar(10),
              buildWaveBar(14),
              buildWaveBar(8),
              buildWaveBar(16),
            ],
          ),
        ],
      );
    }

    if (widget.isProcessing) {
      return const Row(
        key: ValueKey("processing"),
        children: [
          SizedBox(width: 6),
          Text(
            "Processing...",
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ],
      );
    }

    return const SizedBox(key: ValueKey("empty"));
  }
}
