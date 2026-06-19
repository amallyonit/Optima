import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/pages/dashboardPages/customerDashboard/customerDashboardPage.dart';
import 'package:optima/pages/dashboardPages/financesDashboard/biDashboardFinanceContainer.dart';
import 'package:optima/pages/dashboardPages/inventoryDashboardBI/biDashboardInventoryContainer.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/biDashboardProductionContainer.dart';
import 'package:optima/pages/dashboardPages/purchaseDashboard/biDashoardPurchaseContainer.dart';
import 'package:optima/pages/dashboardPages/salesDashboardBI/biDashboardSalesMenuContainer.dart';
import 'package:optima/pages/dashboardPages/salesDashboardBI/salesAnalysis.dart';
import 'package:optima/screens/home.dart';
import 'package:optima/screens/leads.dart';
import '../notificationService.dart';

// ignore: must_be_immutable
class TabsPage extends StatefulWidget {
  int selectedIndex;
  String selectedRoleCode = "";
  TabsPage({
    super.key,
    required this.selectedIndex,
    required this.selectedRoleCode,
  });
  @override
  TabsPageState createState() => TabsPageState();
}

String userRoleCode = "";
String _selectedRoleCode = "";

class TabsPageState extends State<TabsPage> {
  int _selectedIndex = 0;
  void navigateToSalesAnalysis() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SalesPerformancePage()));
  }

  Future<void> _onItemTapped(int index) async {
    setState(() {
      widget.selectedIndex = index;
      _selectedIndex = widget.selectedIndex;
      switch (index) {
        case 2:
          isBiDashboardStart = true;
          break;
        case 3:
          isCustomerDashboardStart = true;
          break;
        default:
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedRoleCode = widget.selectedRoleCode;
    loadTabs();
  }

  Future<void> loadTabs() async {
    final prefs = await SharedPreferences.getInstance();
    userRoleCode = prefs.getString('userRoleCode') ?? '';
    await _onItemTapped(widget.selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(
        body: IndexedStack(
          index: widget.selectedIndex,
          children: [
            for (final tabItem in TabNavigationItem.items) tabItem.page,
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2CA9DF),
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Leads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_outlined),
            label: 'BI Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline_outlined),
            label: 'Customer Data',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        onTap: (index) {
          final isUnauthorized =
              (index == 1 || index == 3) &&
              userRoleCode != "R1" &&
              userRoleCode != "R2";

          if (isUnauthorized) {
            NotificationService.error(
              title: "Access Denied",
              message: "You are not authorized to access this module.",
            );
            return;
          }

          _onItemTapped(index);
        },
      ),
    );
  }
}

class TabNavigationItem {
  final Widget page;
  final Widget title;
  final Icon icon;

  TabNavigationItem({
    required this.page,
    required this.title,
    required this.icon,
  });

  static List<TabNavigationItem> get items => [
    TabNavigationItem(
      page: const Home(),
      icon: const Icon(Icons.home),
      title: const Text("Home"),
    ),
    TabNavigationItem(
      page: const Leads(),
      icon: const Icon(Icons.people),
      title: const Text("Leads"),
    ),

    TabNavigationItem(
      page: _selectedRoleCode.isNotEmpty
          ? (userRoleCode == "R1" || userRoleCode == "R2") &&
                    _selectedRoleCode == "R2"
                ? const SalesBI()
                : (userRoleCode == "R1" || userRoleCode == "R3") &&
                      _selectedRoleCode == "R3"
                ? const FinanceBIPage()
                : (userRoleCode == "R1" || userRoleCode == "R4") &&
                      _selectedRoleCode == "R4"
                ? const PurchaseBI()
                : (userRoleCode == "R1" || userRoleCode == "R5") &&
                      _selectedRoleCode == "R5"
                ? const ProductionFI()
                : (userRoleCode == "R1" || userRoleCode == "R6") &&
                      _selectedRoleCode == "R6"
                ? const InventoryBI()
                : const SalesBI()
          : (userRoleCode == "R1" || userRoleCode == "R2")
          ? const SalesBI()
          : (userRoleCode == "R1" || userRoleCode == "R3")
          ? const FinanceBIPage()
          : (userRoleCode == "R1" || userRoleCode == "R4")
          ? const PurchaseBI()
          : (userRoleCode == "R1" || userRoleCode == "R5")
          ? const ProductionFI()
          : (userRoleCode == "R1" || userRoleCode == "R6")
          ? const InventoryBI()
          : const SalesBI(), // Default case
      icon: const Icon(Icons.dashboard_customize),
      title: const Text("BI Dashboard"),
    ),

    TabNavigationItem(
      page: const CustomerDashboardPage(customerCode: "", initialPage: 0),
      icon: const Icon(Icons.pie_chart_outline_outlined),
      title: const Text("Customer Data"),
    ),
  ];
}
