import 'package:flutter/material.dart';
import 'package:optima/pages/dashboardPages/customerDashboard/customerDashboardPage.dart';
import 'package:optima/pages/dashboardPages/biDashBoardMainMenuContainer.dart';
import 'package:optima/screens/home.dart';
import 'package:optima/screens/leads.dart';

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
      page: const DashboardBIPage(),
      icon: const Icon(Icons.dashboard_customize),
      title: const Text("BI Dashboard"),
    ),
    TabNavigationItem(
      page: const CustomerDashboardPage(customerCode: "", initialPage: 1),
      icon: const Icon(Icons.pie_chart_outline_outlined),
      title: const Text("Customer Data"),
    ),
  ];
}
