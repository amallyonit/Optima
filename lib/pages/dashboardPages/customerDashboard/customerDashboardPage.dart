// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:optima/pages/dashboardPages/customerDashboard/customerDeliverAnalysis.dart';
import 'package:optima/pages/dashboardPages/customerDashboard/customerSalesPerformance.dart';
import 'package:optima/pages/dashboardPages/salesDashboardBI/loaderPage.dart';
import 'package:optima/sidemenu/sidemenu.dart';

String selectedCustomerCode = "";

class CustomerDashboardPage extends StatefulWidget {
  final String customerCode;
  final int initialPage;
  const CustomerDashboardPage({
    super.key,
    required this.customerCode,
    required this.initialPage,
  });

  @override
  CustomerDashboardPageState createState() => CustomerDashboardPageState();
}

class CustomerDashboardPageState extends State<CustomerDashboardPage>
    with SingleTickerProviderStateMixin {
  late PageController pageController;
  List<Widget> pages = [];
  List<String> items = [];
  int current = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.initialPage);

    items = [
      "",
      "Sales \nPerformance",
      "Delivery \nAnalysis",
      "Collection \nAnalysis",
    ];

    pages = [
      const LoaderPage(),
      CustomerSalesPerformancePage(customerCode: widget.customerCode),
      CustomerDeliverAnalysis(customerCode: widget.customerCode),
      const Text(""),
    ];

    if (widget.customerCode != "") {
      selectedCustomerCode = widget.customerCode;
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
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
          "Customer Dashboard",
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
