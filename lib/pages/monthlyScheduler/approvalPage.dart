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
import '../../notificationService.dart';
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
  late TextEditingController participantController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  late Future<void> loadDataFuture;
  int scheduleID = 0;

  String selectedOption = '';
  String selectedParticipantName = "";
  String selectedParticipantId = "";
  String userId = "";
  String userJwtToken = "";
  String userMailID = "";
  var participantKey = GlobalKey();
  Key asyncAutoCompleteKey = UniqueKey();
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
        chartDataLoaded = false;
        participantController.dispose();
      });
      participantController = TextEditingController();
      // Load default data
      await _loadMonthlyScheduler(userId, userJwtToken, userMailID);

      setState(() {
        chartDataLoaded = true;
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
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );
            navigateToLoginScreen();
          } else {
            if (!mounted) return;
            NotificationService.error(
              title: "Error",
              message: responseJson["Error"].toString(),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading customer.",
      );
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
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );
            navigateToLoginScreen();
          } else {
            if (!mounted) return;
            NotificationService.error(
              title: "Error",
              message: "Participant loading failed.",
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading participant.",
      );
    }
  }

  Future<void> loadData() async {
    setState(() {
      chartDataLoaded = false;
    });
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    userJwtToken = prefs.getString('userJwtToken') ?? '';
    userMailID = prefs.getString('userMailID') ?? '';
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
      remarksController.clear();
      remarksController.text = "";
      selectedMonthlyParticipantList = [];
      monthlyParticipantList = [];
      monthlyParticipantList = convertParticipantList(participantList);
      monthlyScheduleList = tmpScheduleList;
      scheduleID = 0;
      DateTime parsedDate = DateFormat(
        'yyyy/MM/dd',
      ).parse(DateFormat('yyyy/MM/dd').format(DateTime.now()));
      DataManager.saveSelectedDateCalendar(parsedDate);
      selectedDate = parsedDate;
    });
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
    monthlyScheduleList = [];
    tmpScheduleList = [];
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'GivenDate': nextMonthLastDay(DateTime.now()),
      // 'GivenDate': selectedMonth.toIso8601String().split(
      //   'T',
      // )[0], // for testing purpose, change to nextMonthLastDay(DateTime.now()) for production
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
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );
            navigateToLoginScreen();
          } else {}
        }
      } else {}
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading monthly schedule.",
      );
    }
  }

  Future<void> approveSchedules() async {
    bool invalidReason = false;

    for (int i = 0; i < _checked.length; i++) {
      if (!_checked[i] && _reasons[i].trim().isEmpty) {
        invalidReason = true;
        break;
      }
    }

    if (invalidReason) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "Please enter reason for rejected schedules",
      );
      return;
    }
    try {
      setState(() {
        chartDataLoaded = false;
      });

      List<Map<String, dynamic>> schedules = [];

      for (int i = 0; i < monthlyScheduleList.length; i++) {
        schedules.add({
          "ScheduleId": monthlyScheduleList[i].scheduleID,
          "ScheduleStatus": _checked[i] ? "A" : "R",
          "ScheduleRemarks": _checked[i] ? "" : _reasons[i],
        });
      }

      final data = {
        "UserJwtToken": userJwtToken,
        "UsermailID": userMailID,
        "Schedules": schedules,
      };

      const apiUrl = '${ApiHelper.baseUrl}updatemonthlyschedulestatus';

      var headers = {HttpHeaders.contentTypeHeader: 'application/json'};

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(data),
      );

      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200 && responseJson["Status"] == true) {
        if (!mounted) return;
        NotificationService.success(
          title: "Success",
          message: "Schedules approved successfully.",
        );
        await _loadMonthlyScheduler(userId, userJwtToken, userMailID);
      } else {
        if (!mounted) return;
        NotificationService.error(
          title: "Error",
          message: "Schedules approval failed.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Schedules approval failed.",
      );
    } finally {
      if (mounted) {
        setState(() {
          chartDataLoaded = true;
        });
      }
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
    participantController = TextEditingController();
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
    remarksController.dispose();
    _reasonController.dispose();
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
              elevation: 1,
              surfaceTintColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Monthly Schedule Approval",
                    style: TextStyle(
                      color: Colors.blue,
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
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
            body: ListView(
              keyboardDismissBehavior: kIsWeb
                  ? ScrollViewKeyboardDismissBehavior.manual
                  : ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.only(top: 20),
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
                                          (ScheduleParticipant option) => option
                                              .scheduleParticipantUserName,
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
                                                      selectedParticipantId =
                                                          "";
                                                      selectedParticipantName =
                                                          "";
                                                      participantController
                                                          .clear();
                                                      monthlyScheduleList
                                                          .clear();
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
                                            Iterable<ScheduleParticipant>
                                            options,
                                          ) {
                                            return Material(
                                              elevation: 4.0,
                                              child: Container(
                                                constraints:
                                                    const BoxConstraints(
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
                                        bottom: 12.0,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: SizedBox(
                                          height:
                                              deviceOrientation == "Portrait"
                                              ? containerHeight
                                              : (containerDropDownHeight / 1.5)
                                                    .clamp(
                                                      48.0,
                                                      double.infinity,
                                                    ),
                                          width: double.infinity,
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: AsyncAutocomplete<ScheduleParticipant>(
                                                  onChanged: (s) {
                                                    setState(() {
                                                      participantController
                                                              .text =
                                                          s;
                                                    });
                                                  },
                                                  onSaved: (s) {
                                                    setState(() {
                                                      participantController
                                                              .text =
                                                          s!;
                                                    });
                                                  },
                                                  maxListHeight:
                                                      deviceOrientation ==
                                                          "Portrait"
                                                      ? 370
                                                      : 220,
                                                  decoration: InputDecoration(
                                                    filled: true,
                                                    fillColor: Colors.white,

                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 12,
                                                        ),

                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),

                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: Color(
                                                                  0xff2ca9df,
                                                                ),
                                                              ),
                                                        ),
                                                    hintText: 'Search',
                                                    hintStyle: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Color(0xFF8F8F8F),
                                                    ),
                                                  ),
                                                  controller:
                                                      participantController,
                                                  inputKey: participantKey,
                                                  onTapItem:
                                                      (
                                                        ScheduleParticipant
                                                        users,
                                                      ) async {
                                                        setState(() {
                                                          participantController
                                                              .text = users
                                                              .scheduleParticipantUserName;
                                                        });
                                                        chartDataLoaded = false;
                                                        String tmpUserId = users
                                                            .scheduleParticipantUserId
                                                            .toString();
                                                        await _loadMonthlyScheduler(
                                                          tmpUserId,
                                                          userJwtToken,
                                                          userMailID,
                                                        );
                                                        setState(() {
                                                          chartDataLoaded =
                                                              true;
                                                        });
                                                      },
                                                  suggestionBuilder: (data) =>
                                                      ListTile(
                                                        title: Text(
                                                          data.scheduleParticipantUserName,
                                                        ),
                                                      ),
                                                  asyncSuggestions:
                                                      (searchValue) =>
                                                          getASM(searchValue),
                                                ),
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: 6,
                                                bottom: 0,
                                                child: Visibility(
                                                  child: SizedBox(
                                                    width: 40,
                                                    child: GestureDetector(
                                                      onTap: () async {
                                                        FocusScope.of(
                                                          context,
                                                        ).unfocus();

                                                        setState(() {
                                                          chartDataLoaded =
                                                              false;

                                                          selectedParticipantId =
                                                              "";
                                                          selectedParticipantName =
                                                              "";

                                                          // recreate controller instead of clearing text
                                                          participantController
                                                              .dispose();

                                                          getASM("");
                                                        });

                                                        await Future.delayed(
                                                          const Duration(
                                                            milliseconds: 100,
                                                          ),
                                                        );

                                                        if (!mounted) return;

                                                        // create fresh controller
                                                        participantController =
                                                            TextEditingController();

                                                        await _loadMonthlyScheduler(
                                                          userId,
                                                          userJwtToken,
                                                          userMailID,
                                                        );

                                                        if (!mounted) return;

                                                        setState(() {
                                                          chartDataLoaded =
                                                              true;
                                                        });
                                                      },
                                                      child: Center(
                                                        child: Icon(
                                                          participantController
                                                                      .text ==
                                                                  ""
                                                              ? Icons.search
                                                              : Icons
                                                                    .cancel_outlined,
                                                          color: const Color(
                                                            0xff2ca9df,
                                                          ),
                                                          size: 22,
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
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      child: monthlyScheduleList.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 100),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "No schedules found",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: monthlyScheduleList.length,
                              itemBuilder: (BuildContext context, int index) {
                                final inputFormat = DateFormat('yyyy/MM/dd');
                                final outputFormat = DateFormat('dd/MM/yyyy');

                                DateTime dateTime = inputFormat.parse(
                                  monthlyScheduleList[index].scheduleDate,
                                );

                                String filterDate = outputFormat.format(
                                  dateTime,
                                );
                                return Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 10),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 5.0,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            const Color(
                                                              0xff2ca9df,
                                                            ).withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        filterDate,
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xff2ca9df,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 8.0,
                                                        ),
                                                    child: Text(
                                                      monthlyScheduleList[index]
                                                          .scheduleCustomerName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Color(
                                                          0xff454545,
                                                        ),
                                                        fontFamily: "Poppins",
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 8.0,
                                                        ),
                                                    child: Text(
                                                      monthlyScheduleList[index]
                                                          .participantList
                                                          .map(
                                                            (e) => e
                                                                .scheduleParticipantUserName,
                                                          )
                                                          .join(', '),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w300,
                                                        color: Color(
                                                          0xff454545,
                                                        ),
                                                        fontFamily: "Poppins",
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 8.0,
                                                        ),
                                                    child: Text(
                                                      monthlyScheduleList[index]
                                                          .scheduleRemarks,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Color(
                                                          0xff454545,
                                                        ),
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
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [],
                                                  ),
                                                  subtitle: _checked[index]
                                                      ? null
                                                      : Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
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
                                                                        FontStyle
                                                                            .italic,
                                                                    fontSize:
                                                                        12,
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
                                                            onPressed: () {
                                                              setState(() {
                                                                _checked[index] =
                                                                    false;
                                                                _reasons[index] =
                                                                    _reasonController
                                                                        .text;
                                                              });
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                            },
                                                            child: const Text(
                                                              'OK',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                            },
                                                            child: const Text(
                                                              'Cancel',
                                                            ),
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
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                    Center(
                      child: Text(
                        scheduleCompleted
                            ? "All schedules have been reviewed."
                            : "Please review all schedules before saving.",
                        style: TextStyle(
                          fontSize: 14,
                          color: scheduleCompleted ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2ca9df),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: scheduleCompleted
                        ? () async {
                            await approveSchedules();
                          }
                        : null,
                    child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          )
        : const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.blue)),
          );
  }
}
