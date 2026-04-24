// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/alertDialog.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import '../sidemenu/sidemenu.dart';
import '../pages/calendar.dart';
import '../pages/homepage.dart';
import '../pages/notificationpage.dart';
import '../pages/searchpage.dart';
// import '../pages/homepagegrids.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  HomeState createState() => HomeState();
}

class NotificationListProvider with ChangeNotifier {
  List<NotificationList> _notificationList = [];
  List<NotificationList> get notificationList => _notificationList;
  void updateNotificationLists(List<NotificationList> newNotificationList) {
    _notificationList = newNotificationList;
    notifyListeners();
  }
}

int notificationCount = 0;

class HomeState extends State<Home> {
  List<Map<String, dynamic>> notiList = [];
  List<NotificationList> notificationList = [];

  @override
  void initState() {
    super.initState();
    notiList = [];
    notificationCount = 0;
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userRoleCode = prefs.getString('userRoleCode') ?? '';
    isUserLoggedIn = await DataManager.readLoginStatus();
    if (isUserLoggedIn &&
        (userRoleCode == "R1" ||
            userRoleCode == "R3" ||
            userRoleCode == "R6")) {
      await loadNotifications(userJwtToken, userMailID, userRoleCode);
    }
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
          notificationList = notiList.toList();
          notificationCount = notificationList.length;
        });
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

  void navigateToNotificationPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationPage()));
  }

  void navigateToSearchPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SearchPage()));
  }

  @override
  void dispose() {
    notiList = [];
    notificationCount = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (onPop) => showExitPopup(context),
      child: Scaffold(
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
                navigateToSearchPage();
              },
            ),
            GestureDetector(
              onTap: () {
                navigateToNotificationPage(); // Clicking anywhere navigates
              },
              child: Stack(
                children: [
                  IconButton(
                    color: const Color(0xFF454545),
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      navigateToNotificationPage();
                    },
                  ),
                  if (notificationCount > 0) // Show badge only if count > 0
                    Positioned(
                      right: 5,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            notificationCount > 99
                                ? '99+'
                                : notificationCount.toString(), // Limit to 99+
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          title: const Text(
            "Home",
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
        ),
        body: const Column(
          children: <Widget>[
            SizedBox(height: 150, child: TableEventsExample()),
            Expanded(child: Card(elevation: 3, child: HomePage())),
          ],
        ),
      ),
    );
  }
}
