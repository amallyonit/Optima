// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:optima/api_helper.dart';
import 'package:optima/login_screen.dart';
import 'package:optima/tabs/tabspage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:optima/classes/leads.dart';
import 'followupeditpage.dart';

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
    loadDataFuture = loadData();
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
    await _selectLeadsDetails(userId, userJwtToken, userMailID);
    if (!filterApplied) {
      await _selectLeadActivity(userId, userJwtToken, userMailID);
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
          } else {
            const snackBar = SnackBar(
              content: Text('Leads details not found.'),
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
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('$e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _selectLeadActivity(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    leadId = widget.leadsId;
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LoadFullCustomerData': 1,
      'LeadId': widget.leadsId,
      'LeadStage': 0,
      'LeadDate': "",
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
        final snackBar = SnackBar(
          content: Text('HTTP Error: ${response.statusCode}'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('$e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('$e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
                          Container(
                            width: containerDropDownWidth,
                            height: containerDropDownHeight,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
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
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 0, top: 1, left: 16, right: 16),
      child: Column(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2CA9DF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16,
                top: 15,
                bottom: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      leadMaster.customerName,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Set text color if needed
                      ),
                      softWrap: true,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                  const Icon(
                    Icons.pie_chart_outline,
                    size: 24,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: const Color(0xFF2CA9DF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Ensure text spans the entire width
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
          ),
          Container(
            color: const Color(
              0xFF2CA9DF,
            ), // Set the desired background color for the container
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16,
                top: 5,
                bottom: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Credit: ${leadMaster.customerPaymentTerms} Days - ${leadMaster.customerCreditLimit}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Colors.white, // Set text color if needed
                    ),
                  ),
                  const Text(
                    '|',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Colors.white, // Set text color if needed
                    ),
                  ),
                  Text(
                    'MOV: ${leadMaster.customerMOV}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Colors.white, // Set text color if needed
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors
                  .white, // Set the desired background color for the container
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16,
                top: 5,
                bottom: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lead No: ${leadMaster.leadID}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Color(0xFF454545), // Set text color if needed
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.swap_calls_sharp,
                        size: 18,
                        color: Color(0xFF454545), // Set icon color if needed
                      ),
                      Text(
                        leadMaster.leadStageLevel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          color: Color(0xFF454545), // Set text color if needed
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Leadsactivity extends StatelessWidget {
  const Leadsactivity({super.key});

  @override
  Widget build(BuildContext context) {
    LeadMaster leadMaster = context.watch<LeadMasterProvider>().leadMaster;
    LeadContactProvider leadContactProvider = context
        .watch<LeadContactProvider>();
    List<LeadContact> leadContacts = leadContactProvider.leadContacts;

    final screenWidth = MediaQuery.of(context).size.width;
    final textFieldWidth = screenWidth;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFCCF0FF),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 13.0,
                right: 16,
                top: 15,
                bottom: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 24,
                    color: Color(0xFF454545),
                  ),
                  const Text(
                    'Lead Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF454545),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FollowUpPage(
                            leadsId: leadId,
                            leadStageForEdit: "0",
                          ),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Color(0xFF454545),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: const Color(0xFFCCF0FF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 0, left: 15),
                  child: Text(
                    leadMaster.leadStartDate,
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
          Container(
            color: const Color(0xFFCCF0FF),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 15,
                top: 5,
                bottom: 15,
                right: 15,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assigned To: ${leadMaster.leadAssigneeName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF454545),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: const Color(0xFFCCF0FF),
            child: const Padding(
              padding: EdgeInsets.only(left: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Contactee',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF454545),
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                for (var item in leadContacts)
                  SizedBox(
                    width: textFieldWidth,
                    height: 50, // Set the desired height
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 0),
                      color: leadContacts.indexOf(item) % 2 == 0
                          ? const Color(0xFFCCF0FF)
                          : const Color(0xFFCCF0FF),
                      child: ListTile(
                        title: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Row(
                            children: [
                              const Icon(Icons.person_4_outlined, size: 16.0),
                              Expanded(
                                child: Text(
                                  item.leadContactName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF454545),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.add_moderator_outlined,
                                size: 16.0,
                              ),
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
        ],
      ),
    );
  }
}

class Leadsactivityhistory extends StatelessWidget {
  final List<LeadActivity> leadActivity;

  const Leadsactivityhistory({super.key, required this.leadActivity});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          for (var item in leadActivity)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              color: const Color(0xFFFFFFFF),
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
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FollowUpPage(
                                  leadsId: item.leadActivityMasterId.toString(),
                                  leadStageForEdit: item.leadActivityStageLevel
                                      .toString(),
                                ),
                              ),
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
