// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import 'package:optima/login_screen.dart';
import 'package:optima/pages/customerdatapage.dart';
import 'package:optima/pages/notificationpage.dart';
import 'package:optima/pages/searchpage.dart';
import 'package:optima/sidemenu/sidemenu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_helper.dart';
import 'package:intl/intl.dart';

bool ascendingOrder = false;

class LeadPageList extends StatefulWidget {
  const LeadPageList({super.key});

  @override
  LeadPageListState createState() => LeadPageListState();
}

class LeadPageListProvider with ChangeNotifier {
  List<LeadList> _leadPageList = [];
  List<LeadList> get leadPageList => _leadPageList;
  void updateLeadLists(List<LeadList> newLeadPageList) {
    _leadPageList = newLeadPageList;
    notifyListeners();
  }
}

class LeadPageListState extends State<LeadPageList> {
  List<Map<String, dynamic>> leadsList = [];
  List<LeadList> leadPageList = [];
  late Future<void> loadDataFuture = loadData();

  @override
  void initState() {
    super.initState();
    leadsList = [];
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    String? filterDate = DateFormat(
      'dd/MM/yyyy',
    ).format(DataManager.readSelectedDate()!).toString();
    filterDate = "";
    if (isUserLoggedIn) {
      await loadOpenLeads(userId, userJwtToken, userMailID, filterDate);
    }
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  String formatDateTime(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
  }

  Future<void> loadOpenLeads(
    String userId,
    String userJwtToken,
    String userMailID,
    String filterDate,
  ) async {
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
    };
    const apiUrl = '${ApiHelper.baseUrl}loadopenleads';
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
            List<LeadList> newLeadsList = data
                .map((item) => LeadList.fromJson(item))
                .toList();
            if (mounted) {
              setState(() {
                context.read<LeadPageListProvider>().updateLeadLists(
                  newLeadsList,
                );
                leadsList = convertLeadListToMapList(newLeadsList);
                if (filterDate != "") {
                  leadsList = leadsList.where((element) {
                    if (element.containsKey('leadFollowupDate')) {
                      String leadFollowupDateString =
                          element['leadFollowupDate'];
                      return leadFollowupDateString == filterDate;
                    }
                    return false;
                  }).toList();
                }
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
          content: Text('Open leads are not available.'),
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

  List<Map<String, String>> convertLeadListToMapList(List<LeadList> leadList) {
    return leadList.map((leadList) {
      return {
        'leadID': leadList.leadID.toString(),
        'leadCustomerName': leadList.leadCustomerName,
        'leadStageLevel': leadList.leadStageLevel,
        'leadStartDate': leadList.leadStartDate,
        'leadAging': leadList.leadAging,
        'leadActivityType': leadList.leadActivityType,
        'leadFollowupDate': leadList.leadFollowupDate,
        'leadFollowupTime': leadList.leadFollowupTime,
      };
    }).toList();
  }

  @override
  void dispose() {
    leadsList = [];
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
              // Display a loading indicator while waiting for data
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              // Handle error state
              return Text('Error: ${snapshot.error}');
            } else {
              return LeadPageListWidget(leadsList: leadsList);
            }
          },
        ),
      ),
    );
  }
}

class LeadPageListWidget extends StatefulWidget {
  final dynamic leadsList;
  const LeadPageListWidget({super.key, required this.leadsList});

  @override
  LeadPageListWidgetState createState() => LeadPageListWidgetState();
}

class LeadPageListWidgetState extends State<LeadPageListWidget> {
  void toggleSortOrder() {
    sortLeadsList(!ascendingOrder);
    ascendingOrder = !ascendingOrder;
  }

  void sortLeadsList(bool ascending) {
    setState(() {
      widget.leadsList.sort((a, b) {
        DateTime dateA = DateFormat('dd/MM/yyyy').parse(a['leadStartDate']);
        DateTime dateB = DateFormat('dd/MM/yyyy').parse(b['leadStartDate']);
        int comparison = dateA.compareTo(dateB);
        return ascending ? comparison : -comparison;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideMenu(),
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return SizedBox(
              child: IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF454545)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        actions: [
          IconButton(
            color: const Color(0xFF454545),
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
          ),
          IconButton(
            color: const Color(0xFF454545),
            icon: const Icon(Icons.notification_add_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
          ),
        ],
        title: const Text(
          "Leads",
          style: TextStyle(
            color: Colors.blue,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.swap_vert),
                onPressed: () {
                  toggleSortOrder();
                },
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: widget.leadsList.length != 0
            ? ListView.builder(
                itemExtent: null,
                itemCount: widget.leadsList.length,
                itemBuilder: (context, index) => Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(10),
                  shape: const RoundedRectangleBorder(),
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerData(
                            leadsId: widget.leadsList[index]["leadID"]
                                .toString(),
                          ),
                        ),
                      );
                    },
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Expanded(
                          child: Container(
                            color: const Color(0xffc0e4f3),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                widget.leadsList[index]["leadCustomerName"],
                                style: const TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff454545),
                                  height: 16 / 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Container(
                      padding: const EdgeInsets.all(1),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text(
                                  'Lead No : ${widget.leadsList[index]["leadID"]}',
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff454545),
                                    height: 13 / 10,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  widget.leadsList[index]["leadStageLevel"],
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff454545),
                                    height: 13 / 10,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  widget.leadsList[index]["leadStartDate"],
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff454545),
                                    height: 13 / 10,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  widget.leadsList[index]["leadAging"],
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff2ca9df),
                                    height: 13 / 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Action Required',
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff6ccc3f),
                                    // color: Color(0xffe92729),
                                    height: 13 / 10,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.leadsList[index]["leadActivityType"],
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff6ccc3f),
                                    // color: Color(0xffe92729),
                                    height: 13 / 10,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                widget.leadsList[index]["leadActivityType"] ==
                                        ""
                                    ? const SizedBox(width: 15)
                                    : const SizedBox(width: 0),
                                Text(
                                  '${widget.leadsList[index]["leadFollowupDate"]}',
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff6ccc3f),
                                    // color: Color(0xffe92729),
                                    height: 13 / 10,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  ' ${widget.leadsList[index]["leadFollowupTime"]}',
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff6ccc3f),
                                    // color: Color(0xffe92729),
                                    height: 13 / 10,
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
              )
            : const Center(
                child: Text("No Leads to Show", style: TextStyle(fontSize: 16)),
              ),
      ),
    );
  }
}
