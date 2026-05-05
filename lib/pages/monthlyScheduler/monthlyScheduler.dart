// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  factory CustomerCommon.fromJson(Map<String, dynamic> json) {
    return CustomerCommon(
      name: json['CustomerName'] ?? '',
      code: json['CustomerCode'] ?? '',
      type: json['CustomerType'] ?? '',
    );
  }
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

final FocusNode customerFocusNode = FocusNode();
final FocusNode searchFocusNode = FocusNode();

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

class _CustomerIndex {
  final CustomerCommon customer;
  final String normalized;
  final List<String> tokens;

  _CustomerIndex(this.customer, this.normalized, this.tokens);
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
  bool _isCustomerListening = false;
  Map<int, TextEditingController> remarksControllers = {};
  Map<int, TextEditingController> customerControllers = {};
  Map<int, TextEditingController> participantControllers = {};
  Timer? _silenceTimer;
  String selectedLocaleId = "en_IN"; // default mixed language
  bool showLanguageSelector = false;
  bool _isSaving = false;
  bool _isRowSaving = false;
  late List<_CustomerIndex> indexedCustomers;

  void buildCustomerIndex(List<Map<String, dynamic>> rawList) {
    indexedCustomers = rawList.map((c) {
      final name = c['CustomerName'] ?? '';
      final normalized = normalize(name);

      return _CustomerIndex(
        CustomerCommon(
          name: name,
          code: c['CustomerCode'] ?? '',
          type: c['CustomerType'] ?? '',
        ),
        normalized,
        normalized.split(' '),
      );
    }).toList();
  }

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
    var headerss = {'Content-Type': 'application/json'};
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
    var headerss = {'Content-Type': 'application/json'};
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
    var headerss = {'Content-Type': 'application/json'};
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
    buildCustomerIndex(customerList);
    selectedDate = DataManager.readSelectedDateCalendar() ?? DateTime.now();
    autoFillMonth();
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
    var headerss = {'Content-Type': 'application/json'};
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
      remarksController.clear();
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

    await addSchedule(newSchedule);
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
      'ScheduleStatus': '', // Default status - Holding
    };
    const apiUrl = '${ApiHelper.baseUrl}loadmonthlyscheduler';
    var headerss = {'Content-Type': 'application/json'};
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
      //if (currentDate.weekday == DateTime.sunday) continue;

      final formattedDate = DateFormat('yyyy/MM/dd').format(currentDate);

      final exists = monthlyScheduleList.any(
        (schedule) => schedule.scheduleDate == formattedDate,
      );

      if (!exists) {
        return false;
      }
    }
    return true;
  }

  Future saveMonthlyScheduler() async {
    setState(() {
      _isSaving = true;
    });
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
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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

  String normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
  }

  Future<void> startListening(MonthlySchedule item, int index) async {
    if (kIsWeb) return;
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
            });
            stopListening(); // force stop after silence
          });
        }
      },
    );
  }

  void stopListening() {
    if (kIsWeb) return;
    _silenceTimer?.cancel();
    _speech?.stop();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    });
  }

  Future<void> initSpeech() async {
    if (kIsWeb) return;
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
          scheduleCustomerType: currentDate.weekday == DateTime.sunday
              ? "S"
              : "H",
          scheduleRemarks: currentDate.weekday == DateTime.sunday
              ? "Sunday"
              : "",
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
  }

  bool isRowValid(MonthlySchedule item) {
    return item.scheduleDate.isNotEmpty &&
        item.scheduleCustomerName.isNotEmpty &&
        item.scheduleCustomerCode.isNotEmpty &&
        item.schedulePriority.isNotEmpty &&
        item.participantList.isNotEmpty;
  }

  bool get isSaveEnabled {
    int year = selectedDate.year;
    int month = selectedDate.month;

    int totalWorkingDays = 0;

    for (int day = 1; day <= DateUtils.getDaysInMonth(year, month); day++) {
      final date = DateTime(year, month, day);
      if (date.weekday != DateTime.sunday) {
        totalWorkingDays++;
      }
    }

    /// Only count NON-SUNDAY dates
    int uniqueWorkingDays = monthlyScheduleList
        .where((e) => e.scheduleCustomerType != "S")
        .map((e) => e.scheduleDate)
        .toSet()
        .length;

    /// Validate only NON-SUNDAY rows
    bool allValid = monthlyScheduleList
        .where((e) => e.scheduleCustomerType != "S")
        .every((e) => isRowValid(e));

    return uniqueWorkingDays >= totalWorkingDays && allValid;
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
                    items: List.generate(50, (i) {
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
      setState(() {});
    }
  }

  Future<void> deleteSchedule(MonthlySchedule item) async {
    final body = {
      "UserID": userId,
      "UserJwtToken": userJwtToken,
      "UsermailID": userMailID,
      "ScheduleID": item.scheduleID,
    };

    const apiUrl = '${ApiHelper.baseUrl}deletemonthlyschedule';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      );

      final res = jsonDecode(response.body);

      if (res["Status"] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Deleted successfully")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["Error"] ?? "Delete failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> startVoiceInput(
    TextEditingController controller,
    MonthlySchedule item,
  ) async {
    if (kIsWeb) return;
    if (!(_speech?.isAvailable ?? false)) return;

    _speech!.listen(
      listenMode: stt.ListenMode.dictation,
      localeId: "en_IN",
      onResult: (result) async {
        if (result.finalResult) {
          String spokenText = result.recognizedWords;

          setState(() {
            _isCustomerListening = false;

            // show what user spoke
            controller.text = spokenText;

            // reset selection → user must choose
            item.scheduleCustomerName = spokenText;
            item.scheduleCustomerCode = "";
            item.scheduleCustomerType = "";
          });

          // GET MATCHING CUSTOMERS
          final results = await searchCustomer(spokenText);

          if (!mounted) return;

          // SHOW BOTTOM SHEET
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              TextEditingController searchController = TextEditingController(
                text: controller.text,
              );

              List<CustomerCommon> filteredList = List.from(results);

              return StatefulBuilder(
                builder: (context, setModalState) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        /// HANDLE (INSIDE UI)
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 6),
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        /// HEADER + SEARCH
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            children: [
                              const Text(
                                "Select Customer",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 10),

                              /// SEARCH FIELD
                              TextField(
                                controller: searchController,
                                focusNode: searchFocusNode,
                                autofocus: false,
                                readOnly: false,
                                onTap: () {
                                  // move cursor to end when user taps
                                  searchController.selection =
                                      TextSelection.fromPosition(
                                        TextPosition(
                                          offset: searchController.text.length,
                                        ),
                                      );
                                },
                                onTapAlwaysCalled: true,
                                decoration: InputDecoration(
                                  hintText: "Search customer...",
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            searchController.clear();
                                            setModalState(() {
                                              filteredList = List.from(results);
                                            });
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),

                                onChanged: (value) {
                                  setModalState(() {
                                    filteredList = results
                                        .where(
                                          (c) => c.name.toLowerCase().contains(
                                            value.toLowerCase(),
                                          ),
                                        )
                                        .toList();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        /// LIST
                        Expanded(
                          child: filteredList.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No matching customers",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: filteredList.length > 10
                                      ? 10
                                      : filteredList.length,
                                  itemBuilder: (context, index) {
                                    final c = filteredList[index];

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          c.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "${c.code} • ${c.type == "H" ? "🏥 Hospital" : "🏢 Distributor"}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            controller.text = c.name;
                                            item.scheduleCustomerName = c.name;
                                            item.scheduleCustomerCode = c.code;
                                            item.scheduleCustomerType = c.type;
                                          });

                                          Navigator.pop(context);
                                        },
                                      ),
                                    );
                                  },
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
      },
    );
  }

  void stopVoiceInput() {
    if (kIsWeb) return;
    _speech!.stop();
  }

  OverlayEntry? _overlayEntry;
  bool _isOverlayVisible = false;

  void _removeOverlay() {
    if (_overlayEntry != null && _isOverlayVisible) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isOverlayVisible = false;
    }
  }

  void _showParticipantSuggestions(
    String query,
    MonthlySchedule item,
    TextEditingController controller,
  ) {
    _removeOverlay(); // safe remove

    if (query.isEmpty) return;

    final results = monthlyParticipantList
        .where(
          (p) =>
              p.scheduleParticipantUserName.toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              !item.participantList.contains(p),
        )
        .take(5)
        .toList();

    if (results.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 20,
          right: 20,
          // top: 300,
          top: MediaQuery.of(context).size.height * 0.35,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ListView(
              shrinkWrap: true,
              children: results.map((p) {
                return ListTile(
                  title: Text(p.scheduleParticipantUserName),
                  onTap: () {
                    setState(() {
                      item.participantList.add(p);
                    });

                    controller.clear();
                    _removeOverlay();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isOverlayVisible = true;
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen =
        !kIsWeb && MediaQuery.of(context).viewInsets.bottom > 0;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final grouped = groupByDate();
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) {
        DateTime dateA = DateFormat('yyyy/MM/dd').parse(a);
        DateTime dateB = DateFormat('yyyy/MM/dd').parse(b);
        return dateA.compareTo(dateB);
      });
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      drawer: const SideMenu(),
      appBar: AppBar(title: const Text("Monthly Plan")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: FutureBuilder(
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

                      /// HIDE when space is tight
                      if (!(isLandscape && isKeyboardOpen)) buildHeaderBanner(),
                      Expanded(
                        child: ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 20,
                          ),
                          itemCount: sortedDates.length,
                          itemBuilder: (context, index) {
                            String date = sortedDates[index];
                            List<MonthlySchedule> items = grouped[date]!;

                            return buildDateGroup(date, items);
                          },
                          // itemCount: groupByDate().keys.length,
                          // itemBuilder: (context, index) {
                          //   final grouped = groupByDate();
                          //   final sortedDates = grouped.keys.toList()
                          //     ..sort((a, b) {
                          //       DateTime dateA = DateFormat('yyyy/MM/dd').parse(a);
                          //       DateTime dateB = DateFormat('yyyy/MM/dd').parse(b);
                          //       return dateA.compareTo(dateB);
                          //     });

                          //   String date = sortedDates[index];
                          //   List<MonthlySchedule> items = grouped[date]!;

                          //   return buildDateGroup(date, items);
                          // },
                        ),
                      ),
                    ],
                  ),

                  /// Loader overlay
                  if (isMonthLoading || _isRowSaving)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.25),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildCustomerAutocomplete(
    MonthlySchedule item,
    TextEditingController controller,
  ) {
    return RawAutocomplete<CustomerCommon>(
      textEditingController: controller,
      focusNode: customerFocusNode,

      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<CustomerCommon>.empty();
        }
        return (await searchCustomer(textEditingValue.text)).take(10);
      },

      displayStringForOption: (option) => option.name,

      onSelected: (CustomerCommon customer) {
        setState(() {
          item.scheduleCustomerName = customer.name;
          item.scheduleCustomerCode = customer.code;
          item.scheduleCustomerType = customer.type;
        });

        controller.text = customer.name;
      },

      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            hintText: "Select Hospital / Distributor",
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            setState(() {
              item.scheduleCustomerName = val;

              if (val.isEmpty) {
                item.scheduleCustomerCode = "";
                item.scheduleCustomerType = "";
              }
            });
          },
        );
      },

      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250, maxWidth: 400),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final customer = options.elementAt(index);

                  return ListTile(
                    dense: true,
                    title: Text(customer.name),
                    subtitle: Text(
                      "${customer.code} • ${customer.type == "H" ? "🏥 Hospital" : "🏢 Distributor"}",
                    ),
                    onTap: () => onSelected(customer),
                  );
                },
              ),
            ),
          ),
        );
      },
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
            onPressed: parsed.weekday == DateTime.sunday
                ? null
                : () => addVisitForDate(date),
            icon: const Icon(Icons.add),
            label: const Text("Add another visit for the day"),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  Widget buildHeaderBanner() {
    int totalDays = List.generate(
      DateUtils.getDaysInMonth(selectedDate.year, selectedDate.month),
      (i) => DateTime(selectedDate.year, selectedDate.month, i + 1),
    ).where((d) => d.weekday != DateTime.sunday).length;

    int filledDays = monthlyScheduleList
        .where(
          (e) =>
              e.scheduleCustomerType != "S" && // exclude Sunday
              isRowValid(e),
        )
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 TOP SECTION (ICON + TEXT)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  "Add all your plan entries for the month. Save will be enabled once all dates have entries.",
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// 🔹 OPTIONAL DIVIDER (clean UI)
          const Divider(height: 1),

          const SizedBox(height: 10),

          /// 🔹 BUTTON (BOTTOM RIGHT)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: (_isSaving || !isComplete)
                    ? null
                    : saveMonthlyScheduler,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isComplete ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text("Save ($filledDays/$totalDays)"),
              ),
            ],
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
    final controller = remarksControllers[index] ??= TextEditingController(
      text: item.scheduleRemarks,
    );
    bool isSunday = item.scheduleCustomerType == "S";
    if (controller.text != item.scheduleRemarks) {
      controller.text = item.scheduleRemarks;
    }
    return Card(
      color: isSunday ? Colors.grey.shade200 : null,
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
                    if (!isSunday) ...[
                      IconButton(
                        icon: Icon(
                          isEditing ? Icons.check : Icons.edit,
                          color: Colors.blue,
                        ),
                        onPressed: () async {
                          if (isEditing) {
                            try {
                              if (_isRowSaving) return;
                              setState(() {
                                _isRowSaving = true;
                              });
                              await addData(item); // API CALL
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isRowSaving = false;
                                  scheduleCompleted = isMonthlyScheduleComplete(
                                    selectedDate,
                                  );
                                  editingIndex = null;
                                });
                              }
                            }
                          } else {
                            setState(() {
                              selectedDate = DateFormat(
                                'yyyy/MM/dd',
                              ).parse(item.scheduleDate);
                              editingIndex = index;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete"),
                              content: const Text(
                                "Are you sure you want to delete this schedule?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("No"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Yes"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            if (item.scheduleID != 0) {
                              await deleteSchedule(item);
                            }

                            setState(() {
                              monthlyScheduleList.removeAt(index);
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),

            isEditing ? const SizedBox(height: 10) : const SizedBox(height: 0),

            /// CUSTOMER
            isEditing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Row → Autocomplete + Tag
                      Row(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (fieldContext) {
                                return Focus(
                                  onFocusChange: (hasFocus) {
                                    if (hasFocus) {
                                      WidgetsBinding.instance.addPostFrameCallback((
                                        _,
                                      ) {
                                        Future.delayed(
                                          const Duration(milliseconds: 200),
                                          () {
                                            if (!mounted) return;

                                            Scrollable.ensureVisible(
                                              fieldContext,
                                              duration: const Duration(
                                                milliseconds: 350,
                                              ),
                                              alignment:
                                                  0.2, // slightly higher than before
                                              curve: Curves.easeInOut,
                                            );
                                          },
                                        );
                                      });
                                    }
                                  },
                                  child: buildCustomerField(item),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: Text(item.scheduleCustomerName)),
                      const SizedBox(width: 6),
                    ],
                  ),

            isEditing ? const SizedBox(height: 8) : const SizedBox(height: 0),

            /// PARTICIPANTS
            isEditing
                ? SizedBox(
                    width: double.infinity,
                    child: SizedBox(
                      width: double.infinity,
                      child: Builder(
                        builder: (fieldContext) {
                          return Focus(
                            onFocusChange: (hasFocus) {
                              if (hasFocus) {
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () {
                                    if (!mounted) return;
                                    Scrollable.ensureVisible(
                                      fieldContext,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      alignment: 0.3,
                                    );
                                  },
                                );
                              }
                            },
                            child: buildParticipantsField(item),
                          );
                        },
                      ),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.start,
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

            isEditing ? const SizedBox(height: 8) : const SizedBox(height: 0),

            /// REMARKS
            isEditing
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // FIXED
                      children: [
                        /// TEXT FIELD
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            maxLines: null,
                            minLines: 1,
                            keyboardType: TextInputType.multiline,

                            decoration: const InputDecoration(
                              hintText: "Remarks",
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),

                            onChanged: (val) {
                              item.scheduleRemarks = val;
                            },
                          ),
                        ),

                        /// CLEAR
                        if (controller.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                controller.clear();
                                item.scheduleRemarks = "";
                              });
                              FocusScope.of(context).unfocus();
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        SizedBox(width: 10),

                        /// SEPARATOR
                        if (controller.text.isNotEmpty)
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey.shade400,
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
                              PopupMenuItem(
                                value: "hi_IN",
                                child: Text("Hindi"),
                              ),
                              PopupMenuItem(
                                value: "ta_IN",
                                child: Text("Tamil"),
                              ),
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

                        /// 🎤 MIC
                        if (!kIsWeb)
                          IconButton(
                            icon: Icon(
                              Icons.mic,
                              size: 20,
                              color: _isListening ? Colors.red : Colors.grey,
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
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Remarks text
                      if (isSunday)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Sunday",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else if (item.scheduleRemarks.isNotEmpty)
                        Expanded(
                          child: Text(
                            item.scheduleRemarks,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),

                      const SizedBox(width: 6),

                      ///  Translate button (ONLY in view mode)
                      if (showLanguageSelector)
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

            isEditing ? const SizedBox(height: 10) : const SizedBox(height: 0),

            // PRIORITY
            isEditing ? buildPriorityField(item) : SizedBox(height: 0),
          ],
        ),
      ),
    );
  }

  Widget buildCustomerField(MonthlySchedule item) {
    final controller = customerControllers[item.hashCode] ??=
        TextEditingController(text: item.scheduleCustomerName);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: !kIsWeb
                ? AsyncAutocomplete<CustomerCommon>(
                    controller: controller,
                    focusNode: customerFocusNode,
                    asyncSuggestions: (query) async {
                      return (await searchCustomer(query)).take(10).toList();
                    },

                    suggestionBuilder: (customer) {
                      return ListTile(
                        dense: true,
                        title: Text(customer.name),
                        subtitle: Text(
                          "${customer.code} • ${customer.type == "H" ? "🏥 Hospital" : "🏢 Distributor"}",
                        ),
                      );
                    },

                    onTapItem: (customer) {
                      setState(() {
                        item.scheduleCustomerName = customer.name;
                        item.scheduleCustomerCode = customer.code;
                        item.scheduleCustomerType = customer.type;
                      });

                      controller.text = customer.name;
                    },

                    onChanged: (val) {
                      setState(() {
                        item.scheduleCustomerName = val;

                        if (val.isEmpty) {
                          item.scheduleCustomerCode = "";
                          item.scheduleCustomerType = "";
                        }
                      });
                    },

                    decoration: const InputDecoration(
                      hintText: "Select Hospital / Distributor",
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero, // IMPORTANT
                    ),
                  )
                : RawAutocomplete<CustomerCommon>(
                    textEditingController: controller,
                    focusNode: customerFocusNode,

                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<CustomerCommon>.empty();
                      }
                      return (await searchCustomer(
                        textEditingValue.text,
                      )).take(10);
                    },

                    displayStringForOption: (option) => option.name,

                    onSelected: (CustomerCommon customer) {
                      setState(() {
                        item.scheduleCustomerName = customer.name;
                        item.scheduleCustomerCode = customer.code;
                        item.scheduleCustomerType = customer.type;
                      });

                      controller.text = customer.name;
                    },

                    fieldViewBuilder:
                        (context, textController, focusNode, onFieldSubmitted) {
                          /// IMPORTANT: reuse SAME controller (no new one)
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              hintText: "Select Hospital / Distributor",
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              setState(() {
                                item.scheduleCustomerName = val;

                                if (val.isEmpty) {
                                  item.scheduleCustomerCode = "";
                                  item.scheduleCustomerType = "";
                                }
                              });
                            },
                          );
                        },

                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 250,
                              maxWidth: 400,
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final customer = options.elementAt(index);

                                return ListTile(
                                  dense: true,
                                  title: Text(customer.name),
                                  subtitle: Text(
                                    "${customer.code} • ${customer.type == "H" ? "🏥 Hospital" : "🏢 Distributor"}",
                                  ),
                                  onTap: () => onSelected(customer),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          /// Clear icon
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  controller.clear();
                  item.scheduleCustomerName = "";
                  item.scheduleCustomerCode = "";
                  item.scheduleCustomerType = "";
                });

                FocusScope.of(context).unfocus();
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ),

          const SizedBox(width: 6),

          controller.text.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 1,
                  height: 30,
                  color: Colors.grey.shade400,
                )
              : SizedBox(height: 30),

          /// Mic icon
          GestureDetector(
            onTap: () async {
              if (_isCustomerListening) {
                if (kIsWeb) return;
                await _speech!.stop();

                setState(() {
                  _isCustomerListening = false;
                });

                // remove focus after stopping
                FocusScope.of(context).unfocus();
              } else {
                setState(() {
                  _isCustomerListening = true;
                });

                startVoiceInput(controller, item);
              }
            },

            child: !kIsWeb
                ? Icon(
                    Icons.mic,
                    size: 20,
                    color: _isCustomerListening ? Colors.red : Colors.grey,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget buildParticipantsField(MonthlySchedule item) {
    final controller = TextEditingController();
    return Stack(
      children: [
        /// MAIN CONTAINER
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10), // space for label
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),

          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              /// CHIPS
              ..._buildParticipantChips(item),

              /// ADD INPUT (pill)
              SizedBox(
                width: 90,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),

                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: "Add",
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            _showParticipantSuggestions(val, item, controller);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        /// FLOATING LABEL
        Positioned(
          left: 4,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            // color: Colors.white, // important (cuts border)
            child: const Text(
              "Participants",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildParticipantChips(MonthlySchedule item) {
    final maxVisible = 3;

    if (item.participantList.length <= maxVisible) {
      return item.participantList.map((p) => _chip(p, item)).toList();
    }

    final visible = item.participantList.take(maxVisible).toList();
    final remaining = item.participantList.length - maxVisible;

    return [
      ...visible.map((p) => _chip(p, item)),

      Chip(label: Text("+$remaining"), backgroundColor: Colors.grey.shade300),
    ];
  }

  Widget _chip(ScheduleParticipant p, MonthlySchedule item) {
    return Chip(
      label: Text(p.scheduleParticipantUserName),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () {
        if (item.participantList.indexOf(p) == 0) return; // block deletion

        setState(() {
          item.participantList.remove(p);
        });
      },
    );
  }

  Widget buildPriorityField(MonthlySchedule item) {
    final priorities = [
      {"label": "Low", "value": "3"},
      {"label": "Medium", "value": "2"},
      {"label": "High", "value": "1"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Priority", style: TextStyle(fontSize: 12)),

        const SizedBox(height: 6),

        Wrap(
          spacing: 8,
          children: priorities.map((p) {
            return ChoiceChip(
              label: Text(p["label"]!),
              selected: item.schedulePriority == p["value"],
              selectedColor: item.schedulePriority == "1"
                  ? Colors.red.shade200
                  : item.schedulePriority == "2"
                  ? Colors.orange.shade200
                  : Colors.green.shade200,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    item.schedulePriority = p["value"]!;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var c in remarksControllers.values) {
      c.dispose();
    }
    for (var c in customerControllers.values) {
      c.dispose();
    }
    _focus.dispose();
    _overlayEntry?.remove();
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
