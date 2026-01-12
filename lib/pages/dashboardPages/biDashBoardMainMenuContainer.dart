// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/pages/dashboardPages/financesDashboard/biDashboardFinanceContainer.dart';
import 'package:optima/pages/dashboardPages/salesDashboardBI/biDashboardSalesMenuContainer.dart';
import 'package:optima/sidemenu/sidemenu.dart';
import 'package:optima/pages/notificationpage.dart';
import 'package:optima/pages/searchpage.dart';
import 'inventoryDashboardBI/biDashboardInventoryContainer.dart';
import 'productionDashboardBI/biDashboardProductionContainer.dart';
import 'purchaseDashboard/biDashoardPurchaseContainer.dart';

class DashboardBIPage extends StatefulWidget {
  const DashboardBIPage({super.key});

  @override
  DashboardBIPageState createState() => DashboardBIPageState();
}

String userRoleCode = "";

class DashboardBIPageState extends State<DashboardBIPage>
    with SingleTickerProviderStateMixin {
  List<String> items = [];
  List<IconData> icons = [];
  List<Widget> pages = [];
  int current = 0;
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userRoleCode = prefs.getString('userRoleCode') ?? '';
    setItemsBasedOnUserRole();
  }

  void setItemsBasedOnUserRole() {
    // Clear any previously set items
    items.clear();
    icons.clear();
    pages.clear();

    items = [
      "Sales",
      "Finance",
      "Purchase",
      "Production",
      "Inventory",
      "Opportunity",
      "Data Integrity",
    ];

    icons = [
      Icons.show_chart_outlined,
      Icons.price_change_outlined,
      Icons.cases_outlined,
      Icons.factory_outlined,
      Icons.inventory_2_outlined,
      Icons.link,
      Icons.data_saver_off_outlined,
    ];

    pages = [
      const SalesBI(),
      const FinanceBIPage(),
      const PurchaseBI(),
      const ProductionFI(),
      const InventoryBI(),
      const Text(""),
      const Text(""),
    ];
    // switch (userRoleCode) {
    //   case 'R1': // Access to all pages
    //     items = [
    //       "Sales",
    //       "Finance",
    //       "Purchase",
    //       "Production",
    //       "Inventory",
    //       "Opportunity",
    //       "Data Integrity",
    //     ];

    //     icons = [
    //       Icons.show_chart_outlined,
    //       Icons.cases_outlined,
    //       Icons.price_change_outlined,
    //       Icons.factory_outlined,
    //       Icons.inventory_2_outlined,
    //       Icons.link,
    //       Icons.data_saver_off_outlined,
    //     ];
    //     pages = [
    //       const SalesBI(),
    //       const FinanceBIPage(),
    //       const PurchaseBI(),
    //       const ProductionFI(),
    //       const InventoryBI(),
    //       const Text(""),
    //       const Text(""),
    //     ];
    //     break;

    //   case 'R2': // Access only to SalesBI
    //     items = ["Sales"];
    //     icons = [Icons.show_chart_outlined];
    //     pages = [const SalesBI()];
    //     break;

    //   case 'R3': // Access only to FinanceBIPage
    //     items = ["Finance"];
    //     icons = [Icons.cases_outlined];
    //     pages = [const FinanceBIPage()];
    //     break;

    //   // Add other user roles similarly
    // }

    setState(() {}); // Update the UI
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
              return RotatedBox(
                quarterTurns: 1,
                child: IconButton(
                  icon: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF454545),
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              );
            },
          ),
          elevation: 0.0,
          actions: [
            IconButton(
              color: const Color(0xFF454545),
              icon: const Icon(Icons.search),
              onPressed: navigateToSearchPage,
            ),
            IconButton(
              color: const Color(0xFF454545),
              icon: const Icon(Icons.notifications_outlined),
              onPressed: navigateToNotificationPage,
            ),
          ],
          title: const Text(
            "BI Dashboard",
            style: TextStyle(
                color: Colors.blue,
                fontFamily: "Poppins",
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: /*Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// Tab Bar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
              Expanded(
                child: SizedBox(
                  height: 40,
                  width: 300,
                  child: ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => const SizedBox(
                            width: 8,
                          ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (ctx, index) {
                        return Column(
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
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: current == index
                                      ? const Color(0xFF2CA9DF)
                                      : Colors.white54,
                                  borderRadius: current == index
                                      ? BorderRadius.circular(25)
                                      : BorderRadius.circular(25),
                                  border: current == index
                                      ? Border.all(
                                          color: const Color(0xFF2CA9DF),
                                          width: 1.5)
                                      : Border.all(
                                          color: Colors.black45, width: 1.5),
                                ),
                                child: Center(
                                  child: Row(
                                    children: [
                                      Icon(
                                        icons[index],
                                        size: current == index ? 23 : 20,
                                        color: current == index
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        items[index],
                                        style: TextStyle(
                                          color: current == index
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                ),
              ),
            ],
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 13),
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
      ),*/

            Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Tab Bar
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centers the widgets in the row
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Aligns them vertically
              children: [
                const SizedBox(
                  width: 15,
                ),
                Flexible(
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (ctx, index) {
                        return GestureDetector(
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
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: current == index
                                  ? const Color(0xFF2CA9DF)
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: current == index
                                    ? const Color(0xFF2CA9DF)
                                    : Colors.black45,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  icons[index],
                                  size: current == index ? 23 : 20,
                                  color: current == index
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  items[index],
                                  style: TextStyle(
                                    color: current == index
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
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
                margin: const EdgeInsets.only(top: 13),
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
        ));
  }

  void navigateToNotificationPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
  }

  void navigateToSearchPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  }
}

// class DashboardBIPageState extends State<DashboardBIPage>
//     with SingleTickerProviderStateMixin {
//   @override
//   void initState() {
//     super.initState();
//     loadData();
//   }

//   Future<void> loadData() async {
//     final prefs = await SharedPreferences.getInstance();
//     userRoleCode = prefs.getString('userRoleCode') ?? '';
//   }

//   List<String> items = [
//     "Sales",
//     "Finance",
//     "Purchase",
//     "Production",
//     "Inventory",
//     "Opportunity",
//     "Data Integrity",
//   ];

//   /// List of body icon
//   List<IconData> icons = [
//     Icons.show_chart_outlined,
//     Icons.cases_outlined,
//     Icons.price_change_outlined,
//     Icons.factory_outlined,
//     Icons.inventory_2_outlined,
//     Icons.link,
//     Icons.data_saver_off_outlined,
//   ];

//   List<Widget> pages = [
//     const SalesBI(),
//     const FinanceBIPage(),
//     const ProductionFI(),
//     const InventoryBI(),
//     const PurchaseBI(),
//     const Text(""),
//     const Text(""),
//   ];
//   int current = 0;
//   PageController pageController = PageController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: const SideMenu(),
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         backgroundColor: Colors.white,
//         leading: Builder(
//           builder: (BuildContext context) {
//             return RotatedBox(
//               quarterTurns: 1,
//               child: IconButton(
//                 icon: const Icon(
//                   Icons.bar_chart_rounded,
//                   color: Color(0xFF454545),
//                 ),
//                 onPressed: () => Scaffold.of(context).openDrawer(),
//               ),
//             );
//           },
//         ),
//         elevation: 0.0,
//         actions: [
//           IconButton(
//             color: const Color(0xFF454545),
//             icon: const Icon(Icons.search),
//             onPressed: navigateToSearchPage,
//           ),
//           IconButton(
//             color: const Color(0xFF454545),
//             icon: const Icon(Icons.notifications_outlined),
//             onPressed: navigateToNotificationPage,
//           ),
//         ],
//         title: const Text(
//           "BI Dashboard",
//           style: TextStyle(
//               color: Colors.blue,
//               fontFamily: "Poppins",
//               fontWeight: FontWeight.bold,
//               fontSize: 18),
//         ),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           /// Tab Bar
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
//               Expanded(
//                 child: SizedBox(
//                   height: 40,
//                   width: 300,
//                   child: ListView.separated(
//                       shrinkWrap: true,
//                       separatorBuilder: (context, index) => const SizedBox(
//                             width: 8,
//                           ),
//                       physics: const BouncingScrollPhysics(),
//                       itemCount: items.length,
//                       scrollDirection: Axis.horizontal,
//                       itemBuilder: (ctx, index) {
//                         return Column(
//                           children: [
//                             GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   current = index;
//                                 });
//                                 pageController.animateToPage(
//                                   current,
//                                   duration: const Duration(milliseconds: 200),
//                                   curve: Curves.ease,
//                                 );
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.all(7),
//                                 decoration: BoxDecoration(
//                                   color: current == index
//                                       ? const Color(0xFF2CA9DF)
//                                       : Colors.white54,
//                                   borderRadius: current == index
//                                       ? BorderRadius.circular(25)
//                                       : BorderRadius.circular(25),
//                                   border: current == index
//                                       ? Border.all(
//                                           color: const Color(0xFF2CA9DF),
//                                           width: 1.5)
//                                       : Border.all(
//                                           color: Colors.black45, width: 1.5),
//                                 ),
//                                 child: Center(
//                                   child: Row(
//                                     children: [
//                                       Icon(
//                                         icons[index],
//                                         size: current == index ? 23 : 20,
//                                         color: current == index
//                                             ? Colors.white
//                                             : Colors.black,
//                                       ),
//                                       const SizedBox(
//                                         width: 10,
//                                       ),
//                                       Text(
//                                         items[index],
//                                         style: TextStyle(
//                                           color: current == index
//                                               ? Colors.white
//                                               : Colors.black,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       }),
//                 ),
//               ),
//             ],
//           ),

//           /// MAIN BODY
//           Expanded(
//             child: Container(
//               margin: const EdgeInsets.only(top: 13),
//               child: PageView.builder(
//                 itemCount: pages.length,
//                 controller: pageController,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemBuilder: (context, index) {
//                   return pages[index];
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void navigateToNotificationPage() {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (_) => const NotificationPage()),
//     );
//   }

//   void navigateToSearchPage() {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (_) => const SearchPage()),
//     );
//   }
// }
