// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/pages/dashboardPages/purchaseDashboard/paymentAnalysis.dart';
import 'package:optima/pages/dashboardPages/purchaseDashboard/poAnalysis.dart';
import 'package:optima/pages/dashboardPages/purchaseDashboard/procurementAnalysis.dart';
import 'package:optima/pages/dashboardPages/purchaseDashboard/procurementLeadTimeAnalysis.dart';
import 'package:optima/pages/dashboardPages/purchaseDashboard/purchasePriceAnalysis.dart';
import 'package:optima/sidemenu/sidemenu.dart';

import '../salesDashboardBI/loaderPage.dart';

class PurchaseBI extends StatefulWidget {
  const PurchaseBI({super.key});

  @override
  State<PurchaseBI> createState() => _PurchaseBIState();
}

String menuPermissionMenuIds = "";

class _PurchaseBIState extends State<PurchaseBI> {
  List<String> items = [
    "",
    "Procurement\nAnalysis",
    "PO\nAnalysis",
    "Payment\nAnalysis",
    "Procurement Lead\nTime Analysis",
    "Purchase Price\nAnalysis",
    "Vendor\nComparison",
  ];

  List<Widget> pages = [
    const LoaderPage(),
    const ProcurementAnalysis(),
    const POAnalysis(),
    const PaymentAnalysis(),
    const ProcurementLeadTimeAnalysis(),
    const PurchasePriceAnalysis(),
    const Text(""),
  ];

  List<int> menuIds = [];
  int current = 0;
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loadMenuPermission(userId, userJwtToken, userMailID);

    _filterPagesByPermission();
  }

  Future<void> _loadMenuPermission(
    String userId,
    String userJwtToken,
    String userMailId,
  ) async {
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailId,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectmenupermission';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty && data[0] is Map<String, dynamic>) {
            menuPermissionMenuIds = data[0]["MenuPermissionMenuIds"].toString();
          }
        }
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _filterPagesByPermission() {
    if (menuPermissionMenuIds == "All") {
      // If "All" is present, assign all available menu IDs
      menuIds = [12, 13, 14, 15, 16, 17]; // Add all available menu IDs here
    } else if (menuPermissionMenuIds.isNotEmpty) {
      menuIds = menuPermissionMenuIds
          .split(',')
          .map((id) => int.parse(id.trim()))
          .toList();
    }

    // Create a map to link menu IDs to pages
    final Map<int, dynamic> menuToPageMap = {
      12: {
        "title": "Procurement\nAnalysis",
        "page": const ProcurementAnalysis(),
      },
      13: {"title": "PO\nAnalysis", "page": const POAnalysis()},
      14: {"title": "Payment\nAnalysis", "page": const PaymentAnalysis()},
      15: {
        "title": "Procurement Lead\nTime Analysis",
        "page": const ProcurementLeadTimeAnalysis(),
      },
      16: {
        "title": "Purchase Price\nAnalysis",
        "page": const PurchasePriceAnalysis(),
      },
      17: {"title": "Vendor\nComparison", "page": const Text("")},
    };

    // Filter the items and pages based on the permission IDs
    items = [""]; // Reset items with the first entry for the loader
    pages = [const LoaderPage()]; // Reset pages with the loader

    for (var id in menuIds) {
      if (menuToPageMap.containsKey(id)) {
        items.add(menuToPageMap[id]["title"]);
        pages.add(menuToPageMap[id]["page"]);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideMenu(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
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
        elevation: 0.0,
        title: const Text(
          "BI Dashboard - Purchase",
          style: TextStyle(
            color: Colors.blue,
            fontFamily: "Poppins",
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: SizedBox(
                    height: 50,
                    child: ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (ctx, index) {
                        return Visibility(
                          visible: index != 0,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    current = index;
                                  });
                                  pageController.animateToPage(
                                    current,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.ease,
                                  );
                                },
                                child: Container(
                                  height: 50,
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white54,
                                    borderRadius: current == index
                                        ? BorderRadius.circular(10)
                                        : BorderRadius.circular(10),
                                    border: current == index
                                        ? Border.all(
                                            color: const Color(0xFF2CA9DF),
                                            width: 1.5,
                                          )
                                        : Border.all(
                                            color: Colors.black45,
                                            width: 1.5,
                                          ),
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Text(
                                        items[index],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: current == index
                                              ? const Color(0xFF2CA9DF)
                                              : Colors.black45,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                child: PageView.builder(
                  itemCount: pages.length,
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return pages[index];
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
