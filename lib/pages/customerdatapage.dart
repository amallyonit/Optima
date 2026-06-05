// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:io';
// import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/leadstages/stagefiveentry.dart';
import 'package:optima/leadstages/stagefourentry.dart';
import 'package:optima/leadstages/stageoneentry.dart';
import 'package:optima/leadstages/stagethreeentry.dart';
import 'package:optima/leadstages/stagetwoentry.dart';
import 'package:optima/login_screen.dart';
// import 'package:optima/pages/dashboardPages/customerDashboard/customerSalesPerformance.dart';
import 'package:optima/tabs/tabspage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:optima/classes/leads.dart';
import '../notificationService.dart';
import 'dashboardPages/customerDashboard/customerDashboardPage.dart';
import 'leadpagelist.dart';

String leadId = "";
List<LeadContact> leadContacts = [];
LeadMaster leadMaster = LeadMaster(
  leadID: 0,
  customerPaymentTerms: 0,
  customerCreditLimit: 0,
  customerMOV: 0,
  customerName: '',
  customerCode: '',
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
);
List<LeadActivity> leadActivity = [];
List<String> departmentList = [];
String selectedDepartment = 'All Department';
bool filterApplied = false;
TextEditingController reasonForClosingController = TextEditingController();

class CustomerData extends StatefulWidget {
  final String leadsId;
  const CustomerData({super.key, required this.leadsId});
  @override
  CustomerDataState createState() => CustomerDataState();
}

class LeadMasterProvider with ChangeNotifier {
  LeadMaster _leadMaster = LeadMaster(
    leadID: 0,
    customerPaymentTerms: 0,
    customerCreditLimit: 0,
    customerMOV: 0,
    customerName: '',
    customerCode: '',
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
  );

  LeadMaster get leadMaster => _leadMaster;
  void updateLeadMaster(LeadMaster newLeadMaster) {
    _leadMaster = newLeadMaster;
    notifyListeners(); // Notify listeners to rebuild widgets
  }
}

class LeadActivityCustomerDataProvider with ChangeNotifier {
  List<LeadActivity> _leadActivity = [];
  List<LeadActivity> get leadActivity => _leadActivity;
  void updateLeadActivity(List<LeadActivity> newLeadActivity) {
    _leadActivity = newLeadActivity;
    notifyListeners();
  }
}

class LeadContactProvider with ChangeNotifier {
  List<LeadContact> _leadContacts = [];
  List<LeadContact> get leadContacts => _leadContacts;
  void updateLeadContacts(List<LeadContact> newLeadContacts) {
    _leadContacts = newLeadContacts;
    notifyListeners();
  }
}

class CustomerDataState extends State<CustomerData> {
  late Future<void> loadDataFuture;
  List<LeadActivity> unFilteredLeadActivity = [];
  final _leadSearchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (isUserLoggedIn) {
      loadDataFuture = loadData();
    }
  }

  void filterLeadActivity() {
    if (selectedDepartment != "All Department") {
      setState(() {
        filterApplied = true;
        leadActivity = unFilteredLeadActivity;
        leadActivity = leadActivity
            .where(
              (activity) => activity.leadActivityDepartment
                  .toLowerCase()
                  .contains(selectedDepartment.toLowerCase()),
            )
            .toList();
      });
    } else {
      setState(() {
        filterApplied = false;
        leadActivity = unFilteredLeadActivity;
      });
    }
  }

  void filterLeadActivityWithLeadNo(String leadNo) {
    if (leadNo != "") {
      setState(() {
        filterApplied = true;
        leadActivity = unFilteredLeadActivity;
        leadActivity = leadActivity
            .where(
              (activity) => activity.leadActivityMasterId
                  .toString()
                  .toLowerCase()
                  .contains(leadNo.toLowerCase()),
            )
            .toList();
      });
    } else {
      setState(() {
        filterApplied = false;
        leadActivity = unFilteredLeadActivity;
      });
    }
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    String? filterDate = DateFormat(
      'dd/MM/yyyy',
    ).format(DataManager.readSelectedDate()!).toString();
    await _selectLeadsDetails(userId, userJwtToken, userMailID);
    if (!filterApplied) {
      await _selectLeadActivity(userId, userJwtToken, userMailID, filterDate);
    }
    await _loadDepartment();
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _selectLeadsDetails(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    leadId = widget.leadsId;
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadId': widget.leadsId,
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
                  context.read<LeadMasterProvider>().updateLeadMaster(
                    LeadMaster.fromJson(masData as Map<String, dynamic>),
                  );
                });
              }
            }
            if (data.length > 1 && data[1] is List) {
              List<LeadContact> newLeadContacts = (data[1] as List)
                  .map((item) => LeadContact.fromJson(item))
                  .toList();
              setState(() {
                context.read<LeadContactProvider>().updateLeadContacts(
                  newLeadContacts,
                );
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
        message: "Error occured while loading lead details.",
      );
    }
  }

  Future<void> _selectLeadActivity(
    String userId,
    String userJwtToken,
    String userMailID,
    String filterDate,
  ) async {
    leadId = widget.leadsId;
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LoadFullCustomerData': 1,
      'LeadId': 0,
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
                context
                    .read<LeadActivityCustomerDataProvider>()
                    .updateLeadActivity(newLeadActivity);
                leadActivity = newLeadActivity;
                unFilteredLeadActivity = leadActivity;
              });
            }
          } else {
            if (!mounted) return;
            NotificationService.info(
              title: "Info",
              message: "Leads activity details not found.",
            );
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
        message: "Error occured while loading lead activities.",
      );
    }
  }

  Future<void> _loadDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final data = {'UserJwtToken': userJwtToken, 'UsermailID': userMailID};
    const apiUrl = '${ApiHelper.baseUrl}selectleadcontactdepartment';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        departmentList = [];
        selectedDepartment = 'All Department';
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        // int dataLength = data.length;
        if (status && responseJson["Data"].toString().isNotEmpty) {
          final List data = jsonDecode(response.body)["Data"];
          List<String> newDepartmentList = [];
          for (var item in data) {
            newDepartmentList.add(item["LeadContactDepartment"]);
          }
          setState(() {
            departmentList = newDepartmentList;
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
        message: "Error occured while loading department details.",
      );
    }
  }

  @override
  void dispose() {
    leadContacts = [];
    leadActivity = [];
    unFilteredLeadActivity = [];
    departmentList = [];
    selectedDepartment = 'All Department';
    super.dispose();
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

  Widget customerData() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textFieldWidth = screenWidth / 2;
    final textFieldHeight = screenHeight * 0.06;
    final containerDropDownWidth = screenWidth / 2.5;
    final containerDropDownHeight = screenHeight * 0.06;

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black, // Set the icon color to black
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    TabsPage(selectedIndex: 1, selectedRoleCode: ""),
              ),
            );
          },
        ),
        backgroundColor: Colors.white, // Set the background color to white
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: <Widget>[
                const Leadsdetails(),
                const SizedBox(height: 0),
                const Leadsactivity(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: const Divider(color: Colors.grey, thickness: 1.0),
                ),
                Column(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Row(
                        children: <Widget>[
                          Text(
                            "Activity History",
                            style: TextStyle(
                              color: Color(0xFF2CA9DF),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.blue,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: textFieldWidth - 10,
                            height: textFieldHeight,
                            child: TextField(
                              controller: _leadSearchController,
                              keyboardType: TextInputType.number,
                              onChanged: (text) {
                                filterLeadActivityWithLeadNo(text);
                              },
                              decoration: InputDecoration(
                                hintText: "Search by lead no.",
                                border: UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: const Color.fromARGB(
                                  255,
                                  255,
                                  255,
                                  255,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 5.0,
                                  horizontal: 5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 17),
                          // ignore: sized_box_for_whitespace
                          Container(
                            width: containerDropDownWidth,
                            height: containerDropDownHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedDepartment,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedDepartment = newValue!;
                                    filterLeadActivity();
                                  });
                                },
                                underline: const SizedBox(),
                                style: const TextStyle(
                                  color: Color(0xFF454545),
                                  fontSize: 16,
                                ),
                                items: departmentList.map((department) {
                                  return DropdownMenuItem<String>(
                                    value: department,
                                    child: Text(department),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Leadsactivityhistory(leadActivity: leadActivity),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Leadsdetails extends StatelessWidget {
  const Leadsdetails({super.key});

  @override
  Widget build(BuildContext context) {
    LeadMaster leadMaster = context.watch<LeadMasterProvider>().leadMaster;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      elevation: 4,
      color: const Color(0xff2ca9df),
      margin: const EdgeInsets.only(bottom: 0, top: 5, left: 16, right: 16),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16,
              top: 8,
              bottom: 5,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    leadMaster.customerName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xfffdfdfd),
                      fontFamily: "Poppins",
                    ),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerDashboardPage(
                          customerCode: leadMaster.customerCode,
                          initialPage: 1,
                        ),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.pie_chart_outline,
                    size: 20,
                    color: Color(0xfffdfdfd),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 5,
                  bottom: 0,
                  left: 15,
                  right: 0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width -
                        60, // Adjust the width constraint as needed
                  ),
                  child: Text(
                    leadMaster.customerAddress,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Credit: ${leadMaster.customerPaymentTerms} Days - ${leadMaster.customerCreditLimit}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "Poppins",
                    color: Color(0xfffdfdfd),
                  ),
                ),
                const Text(
                  '|',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xfffdfdfd),
                  ),
                ),
                Text(
                  'MOV: ${leadMaster.customerMOV}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "Poppins",
                    color: Color(0xfffdfdfd),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        'Lead No: ${leadMaster.leadID}',
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff454545),
                          height: 13 / 10,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    leadMaster.leadStageLevel,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff454545),
                      height: 13 / 10,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeadPageList(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Other Leads",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff2ca9df),
                        height: 13 / 10,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Leadsactivity extends StatefulWidget {
  const Leadsactivity({super.key});
  @override
  LeadsactivityState createState() => LeadsactivityState();
}

class LeadsactivityState extends State<Leadsactivity> {
  @override
  void initState() {
    super.initState();
  }

  void navigateToStages(int leadStage, String leadId) {
    switch (leadStage) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageOneLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageTwoLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageThreeLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageFourLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageFiveLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    LeadMaster leadMaster = context.watch<LeadMasterProvider>().leadMaster;
    // List<LeadActivity> leadActivity =
    //     context.watch<LeadActivityCustomerDataProvider>().leadActivity;
    LeadActivity? activityItem;

    for (var item in leadActivity.where(
      (element) => element.leadActivityStageLevel == leadMaster.leadStage,
    )) {
      activityItem = item;
      break;
    }
    return Card(
      color: const Color.fromARGB(255, 191, 241, 255),
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline, color: Color(0xff8f8f8f)),
                    SizedBox(width: 4),
                    Text(
                      "Lead Details",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff454545),
                      ),
                    ),
                  ],
                ),
                ReasonForClosingPopUp(),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leadMaster.leadStartDate.substring(0, 10),
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w400,
                    color: Color(0xff454545),
                    fontSize: 13,
                  ),
                ),
                Text(
                  leadMaster.leadStageLevel,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w400,
                    color: Color(0xff454545),
                    fontSize: 13,
                  ),
                ),
                Text(
                  leadMaster.leadAging,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w400,
                    color: Color(0xff454545),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    leadMaster.leadProductName,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w400,
                      color: Color(0xff454545),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activityItem?.leadActivityStatus ?? "",
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 13,
                    color: Color(0xffe92729),
                    // height: 19 / 10,
                  ),
                  textAlign: TextAlign.left,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.computer_outlined,
                      color: Color(0xffe92729),
                      size: 18,
                    ),
                    Text(
                      activityItem?.leadActivityType ?? "",
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 13,
                        color: Color(0xffe92729),
                        height: 19 / 10,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    activityItem?.leadActivityFollowupDate ?? "",
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 13,
                      color: Color(0xffe92729),
                      height: 13 / 10,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: InkWell(
                    onTap: () {
                      navigateToStages(leadMaster.leadStage, leadId);
                    },
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: Color(0xFF454545),
                    ),
                  ),
                ),
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Contactee",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff454545),
                    height: 13 / 10,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
            const SizedBox(height: 85, child: CustomListItemForCustomerData()),
          ],
        ),
      ),
    );
  }
}

class CustomListItemForCustomerData extends StatelessWidget {
  const CustomListItemForCustomerData({super.key});

  @override
  Widget build(BuildContext context) {
    LeadContactProvider leadContactProvider = context
        .watch<LeadContactProvider>();
    List<LeadContact> leadContacts = leadContactProvider.leadContacts;
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
                                fontFamily: 'Poppins',
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
                                fontFamily: 'Poppins',
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

class ReasonForClosingPopUp extends StatefulWidget {
  const ReasonForClosingPopUp({super.key});

  @override
  State<ReasonForClosingPopUp> createState() => _ReasonForClosingPopUpState();
}

class _ReasonForClosingPopUpState extends State<ReasonForClosingPopUp> {
  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> leadEntryClose() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadId': leadId,
      'LeadStatus': 'C',
      'LeadSummary': reasonForClosingController.text,
    };
    const apiUrl = '${ApiHelper.baseUrl}updateleadentrymasterstatus';
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

        if (status) {
          setState(() {
            reasonForClosingController.text = "";
          });

          if (!mounted) return;
          NotificationService.success(
            title: "Success",
            message: "Lead closed successfully.",
          );
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
        message: "Error occured while closing lead entry.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    LeadMaster leadMaster = context.watch<LeadMasterProvider>().leadMaster;
    return TextButton(
      onPressed: () => showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date : ${leadMaster.leadStartDate.substring(0, 10)}',
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff454545),
                    ),
                  ),
                  Text(
                    leadMaster.leadStageLevel,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff454545),
                    ),
                  ),
                  Text(
                    leadMaster.leadAging,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff454545),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      leadMaster.leadProductName,
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff454545),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Reason for Closing",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff454545),
                    height: 13 / 10,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(0),
                ),
                padding: const EdgeInsets.all(5),
                child: TextField(
                  controller: reasonForClosingController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '',
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xff2ca9df),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff010100),
                      height: 10 / 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    leadEntryClose();
                    try {
                      await leadEntryClose();
                      Navigator.pop(context, 'OK');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LeadPageList(),
                        ),
                      );
                    } catch (error) {
                      // print('Error: $error');
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xff2ca9df),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff010100),
                      height: 10 / 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      child: RichText(
        text: const TextSpan(
          text: 'Close Lead',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xfff49136),
            height: 9 / 10,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xfff49136),
            decorationThickness: 1.0,
          ),
        ),
      ),
    );
  }
}

class Leadsactivityhistory extends StatefulWidget {
  final List<LeadActivity> leadActivity;
  const Leadsactivityhistory({super.key, required this.leadActivity});
  @override
  LeadsactivityhistoryState createState() => LeadsactivityhistoryState();
}

class LeadsactivityhistoryState extends State<Leadsactivityhistory> {
  @override
  void initState() {
    super.initState();
  }

  void navigateToStages(int leadStage, String leadId) {
    switch (leadStage) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageOneLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageTwoLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageThreeLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageFourLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageFiveLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    LeadMaster leadMaster = context.watch<LeadMasterProvider>().leadMaster;
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          for (var item in leadActivity.where(
            (element) => element.leadCustomerName == leadMaster.customerName,
          ))
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8F8F8F)),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  'Start Date: ${item.leadActivityStartDate}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF454545),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  'Participants : ${item.leadParticipantUserName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF454545),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 15),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // Set crossAxisAlignment to start for left-alignment
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                'Lead No ${item.leadActivityMasterId}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF454545),
                                  // Apply TextAlign.left for left-alignment
                                ),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Stage ${item.leadActivityStageLevel}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF454545),
                                  // Apply TextAlign.left for left-alignment
                                ),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Summary: ${item.leadActivitySummary}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF454545),
                                  // Apply TextAlign.left for left-alignment
                                ),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Follow up date: ${item.leadActivityFollowupDate}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF454545),
                                  // Apply TextAlign.left for left-alignment
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                        // Other ListTiles
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            navigateToStages(
                              item.leadActivityStageLevel,
                              item.leadActivityMasterId.toString(),
                            );
                          },
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.black, // Change icon color
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 100,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEAEAEA,
                            ), // Change background color
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: const Color(0xFF6CCC3F), // Border color
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 15,
                                right: 10,
                              ),
                              child: Text(
                                item.leadProductName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF454545),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ), // Add space between text and icon
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Status : ${item.leadActivityStatus}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Color(0xFF6CCC3F),
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
  }
}
