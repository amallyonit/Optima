// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/login_screen.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  NotificationPageState createState() => NotificationPageState();
}

class NotificationListProvider with ChangeNotifier {
  List<NotificationList> _notificationList = [];
  List<NotificationList> get notificationList => _notificationList;
  void updateNotificationLists(List<NotificationList> newNotificationList) {
    _notificationList = newNotificationList;
    notifyListeners();
  }
}

late Future<void> loadDataFuture;

class NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notiList = [];
  List<NotificationList> notificationList = [];
  // Map to track expanded state for each department
  Map<String, bool> expandedState = {};
  bool isLoading = true; // Show loading indicator

  @override
  void initState() {
    super.initState();
    notiList = [];
    loadDataFuture = loadData();
  }

  void _initializeExpansionState() {
    for (var item in notificationList) {
      expandedState[item.department] = expandedState[item.department] ?? false;
    }
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userRoleCode = prefs.getString('userRoleCode') ?? '';
    if (isUserLoggedIn &&
        (userRoleCode == "R1" ||
            userRoleCode == "R3" ||
            userRoleCode == "R6")) {
      await loadNotifications(userJwtToken, userMailID, userRoleCode);
    } else {
      setState(() {
        isLoading = false;
      });
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

  Future<void> loadNotifications(
    String userJwtToken,
    String userMailID,
    String userRoleCode,
  ) async {
    List<NotificationList> notiList = [];
    final data = {'Index': 0, 'Limit': 1000};
    String department = "";
    if (userRoleCode == "R3") {
      department = "Accounts and Finance";
    } else if (userRoleCode == "R6") {
      department = "Regulatory Affairs";
    }
    const apiUrl = '${ApiHelper.baseUrl}BicxoAlertsList';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson["responseData"].toString().isNotEmpty) {
          List<NotificationList> newNotificationList =
              (responseJson['responseData'] as List)
                  .map((item) => NotificationList.fromJson(item))
                  .toList();
          List<NotificationList> filteredList = department.isNotEmpty
              ? newNotificationList.where((notification) {
                  return notification.department.contains(department);
                }).toList()
              : newNotificationList;
          filteredList.sort((a, b) => a.department.compareTo(b.department));
          notiList.addAll(filteredList);
        }
        setState(() {
          context.read<NotificationListProvider>().updateNotificationLists(
            notiList,
          );
          notificationList = notiList.toList();
          _initializeExpansionState();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  void dispose() {
    notificationList = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Show loading indicator while fetching data
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Notification Page',
            style: TextStyle(
              color: Color(0xFF2CA9DF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 🔹 Group notifications by department
    Map<String, List<NotificationList>> groupedNotifications = {};
    for (var item in notificationList) {
      groupedNotifications.putIfAbsent(item.department, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Page',
          style: TextStyle(
            color: Color(0xFF2CA9DF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: groupedNotifications.keys.map((department) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Department Header (Expandable)
              GestureDetector(
                onTap: () {
                  setState(() {
                    expandedState[department] = !expandedState[department]!;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: expandedState[department]!
                      ? Colors.blue[100]
                      : Colors.blue[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        department,
                        style: const TextStyle(
                          color: Color(0xFF2CA9DF),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        expandedState[department]!
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),

              // 🔹 Expand/Collapse List
              if (expandedState[department]!)
                ...groupedNotifications[department]!.map((notification) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          border: const Border(
                            left: BorderSide(
                              color: Color(0xFF2CA9DF),
                              width: 5.0,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.2),
                              spreadRadius: 2,
                              blurRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.alertName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text('Location: ${notification.location}'),
                              const SizedBox(height: 5),
                              Text('Vendor: ${notification.vendorName}'),
                              const SizedBox(height: 5),
                              Text('Due Date: ${notification.dueDate}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Notification Page '),
  //     ),
  //     body: SingleChildScrollView(
  //       child: Column(
  //         children: [
  //           const SizedBox(
  //             height: 10,
  //           ),
  //           const Row(
  //             mainAxisAlignment: MainAxisAlignment.start,
  //             children: [
  //               SizedBox(
  //                 width: 10,
  //               ),
  //               Text(
  //                 "Finance",
  //                 style: TextStyle(
  //                     color: Colors.blue,
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(
  //             height: 10,
  //           ),
  //           SizedBox(
  //             height: 700,
  //             child: ListView.separated(
  //                 separatorBuilder: (BuildContext context, int i) {
  //                   return const SizedBox(
  //                     height: 10,
  //                   );
  //                 },
  //                 itemCount: notificationList.length,
  //                 itemBuilder: (BuildContext context, int i) {
  //                   return Padding(
  //                     padding: const EdgeInsets.only(
  //                         left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
  //                     child: Container(
  //                       decoration: BoxDecoration(
  //                         border: const Border(
  //                           left: BorderSide(
  //                             color: Colors.blue, // Left border color
  //                             width: 5.0, // Left border thickness
  //                           ),
  //                         ),
  //                         boxShadow: [
  //                           BoxShadow(
  //                             color: Colors.grey.withValues(alpha:0.2),
  //                             spreadRadius: 8,
  //                             blurRadius: 1,
  //                             offset: const Offset(
  //                                 0, 6), // changes position of shadow
  //                           ),
  //                         ],
  //                       ),
  //                       child: Column(
  //                         children: [
  //                           const SizedBox(
  //                             height: 5,
  //                           ),
  //                           Align(
  //                             alignment: Alignment
  //                                 .centerLeft, // Ensures full left alignment
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment
  //                                   .start, // Align text to the left
  //                               children: [
  //                                 Padding(
  //                                   padding: const EdgeInsets.symmetric(
  //                                       horizontal: 10.0),
  //                                   child: Text(
  //                                     notificationList[i].alertName,
  //                                     style: const TextStyle(fontSize: 14),
  //                                     maxLines: null, // Allows unlimited lines
  //                                     softWrap: true, // Enables wrapping
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                           const SizedBox(
  //                             height: 5,
  //                           ),
  //                           Row(
  //                             children: [
  //                               Padding(
  //                                 padding: const EdgeInsets.only(left: 10.0),
  //                                 child: Text(notificationList[i].location),
  //                               ),
  //                             ],
  //                           ),
  //                           const SizedBox(
  //                             height: 5,
  //                           ),
  //                           Row(
  //                             children: [
  //                               Padding(
  //                                 padding: const EdgeInsets.only(left: 10.0),
  //                                 child: Text(notificationList[i].vendorName),
  //                               ),
  //                             ],
  //                           ),
  //                           const SizedBox(
  //                             height: 5,
  //                           ),
  //                           Row(
  //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                             children: [
  //                               Padding(
  //                                 padding: const EdgeInsets.only(left: 10.0),
  //                                 child: Text(
  //                                     'Due date: ${notificationList[i].dueDate}'),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   );
  //                 }),
  //           ),
  //           const SizedBox(height: 20),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
